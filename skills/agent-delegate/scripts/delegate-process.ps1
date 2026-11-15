# Streams child process output and preserves private diagnostics.

function New-DelegateProcessJob {
    if (-not $IsWindows) { return $null }
    if (-not ('AgentDelegate.ProcessJob' -as [type])) { Add-Type -Path "$PSScriptRoot/delegate-process-job.cs" }
    return [AgentDelegate.ProcessJob]::new()
}

function New-DelegateProcessInfo {
    param($Command, [string[]]$Arguments, [string]$Directory, [hashtable]$Environment)
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName, $info.WorkingDirectory = $Command.Source, $Directory
    $info.UseShellExecute = $false
    $info.RedirectStandardInput = $info.RedirectStandardOutput = $info.RedirectStandardError = $true
    $info.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
    $info.StandardOutputEncoding = $info.StandardErrorEncoding = [Text.Encoding]::UTF8
    $info.Environment['GIT_CEILING_DIRECTORIES'] = Split-Path -Parent $Directory
    foreach ($name in $Environment.Keys) { $info.Environment[$name] = $Environment[$name] }
    foreach ($name in @('CLAUDECODE', 'CLAUDE_CODE_SUBAGENT_MODEL', 'GIT_DIR', 'GIT_WORK_TREE')) {
        [void]$info.Environment.Remove($name)
    }
    if ($Command.Source.EndsWith('.ps1', [StringComparison]::OrdinalIgnoreCase)) {
        $info.FileName = (Get-Process -Id $PID).Path
        $Arguments = @('-NoProfile', '-File', $Command.Source) + $Arguments
    }
    foreach ($arg in $Arguments) { $info.ArgumentList.Add($arg) }
    return $info
}

function New-DelegateCapture {
    param($Process, $Command, [hashtable]$Environment)
    if (-not $script:DelegateLogDirectory) {
        $script:DelegateLogDirectory = [IO.Directory]::CreateTempSubdirectory('agent-delegate-logs-').FullName
    }
    $script:DelegateProcessNumber++
    $capture = @{
        Timer = [Diagnostics.Stopwatch]::StartNew(); Status = 'running'; ExitCode = $null
        Command = $Command.Name; ProcessId = $Process.Id; FirstOutputSeconds = $null; LastOutputSeconds = $null
        LastEvent = 'starting'; Events = 0; ResultReceived = $false; ProgressReports = 0; Job = $null; TreeOwnership = 'live-root'
        Environment = $Environment; Base = Join-Path $script:DelegateLogDirectory ('process-{0:D2}' -f $script:DelegateProcessNumber)
    }
    foreach ($entry in @(@('Stdout', $Process.StandardOutput), @('Stderr', $Process.StandardError))) {
        $buffer = [char[]]::new(8192)
        $capture[$entry[0]] = @{ Name = $entry[0]; Reader = $entry[1]; Buffer = $buffer; Pending = $entry[1].ReadAsync($buffer, 0, $buffer.Length)
            Ended = $false; Partial = ''; Text = [Text.StringBuilder]::new() }
    }
    return $capture
}

function Get-DelegateEventLabel {
    param([string]$Line, [hashtable]$Capture)
    if (-not $Line.TrimStart().StartsWith('{')) { return 'stdout' }
    try { $event = $Line | ConvertFrom-Json -ErrorAction Stop } catch { return 'stdout' }
    if ($event.type -notmatch '^[a-zA-Z0-9_.-]{1,64}$') { return 'stdout' }
    $Capture.Events++
    if ($event.type -eq 'result') { $Capture.ResultReceived = $true }
    $detail = $event.subtype
    if ($event.type -eq 'stream_event') { $detail = $event.event.type }
    if ($event.type -eq 'assistant') {
        $tool = $event.message.content | Where-Object type -EQ 'tool_use' | Select-Object -First 1
        if ($tool) { $detail = $tool.name }
    }
    if ($detail -match '^[a-zA-Z0-9_.-]{1,64}$') { return "$($event.type):$detail" }
    return [string]$event.type
}

function Receive-DelegatePipe {
    param([hashtable]$Pipe, [hashtable]$Capture)
    for ($i = 0; $i -lt 100 -and -not $Pipe.Ended -and $Pipe.Pending.IsCompleted; $i++) {
        $count = $Pipe.Pending.GetAwaiter().GetResult()
        if ($count -eq 0) {
            $Pipe.Ended = $true
            if ($Pipe.Name -eq 'Stdout' -and $Pipe.Partial) { $Capture.LastEvent = Get-DelegateEventLabel $Pipe.Partial $Capture }
            break
        }
        $chunk = [string]::new($Pipe.Buffer, 0, $count)
        [void]$Pipe.Text.Append($chunk)
        $Capture.LastOutputSeconds = $Capture.Timer.Elapsed.TotalSeconds
        if ($null -eq $Capture.FirstOutputSeconds) { $Capture.FirstOutputSeconds = $Capture.LastOutputSeconds }
        $parts = ($Pipe.Partial + $chunk) -split "`n"
        for ($line = 0; $line -lt $parts.Length - 1; $line++) {
            $Capture.LastEvent = if ($Pipe.Name -eq 'Stdout') { Get-DelegateEventLabel $parts[$line].TrimEnd("`r") $Capture } else { 'stderr' }
        }
        $Pipe.Partial = $parts[-1]
        if ($Pipe.Name -eq 'Stderr') { $Capture.LastEvent = 'stderr' }
        $Pipe.Pending = $Pipe.Reader.ReadAsync($Pipe.Buffer, 0, $Pipe.Buffer.Length)
    }
}

function Protect-DelegateDiagnostic {
    param([string]$Text, [hashtable]$Environment)
    $entries = @($Environment.GetEnumerator()) + @([Environment]::GetEnvironmentVariables('Process').GetEnumerator())
    foreach ($entry in $entries) {
        if ($entry.Value -and $entry.Key -match 'TOKEN|KEY|SECRET|PASSWORD|HEADERS|BASE_URL') {
            $values = @([string]$entry.Value)
            if ($entry.Key -match 'HEADERS') {
                foreach ($header in ([string]$entry.Value -split '\r?\n')) {
                    $pair = $header.Split(':', 2)
                    if ($pair.Length -eq 2 -and $pair[0].Trim() -match '^[A-Za-z0-9_-]+$') {
                        $values += $pair[1].Trim()
                        if ($pair[1].Trim() -match '^(?:Bearer|Basic)\s+(.+)$') { $values += $Matches[1] }
                    }
                }
            }
            foreach ($value in ($values | Where-Object { $_ } | Select-Object -Unique | Sort-Object Length -Descending)) {
                $Text = $Text.Replace($value, '[redacted]')
                $escaped = ConvertTo-Json -InputObject $value -Compress
                $Text = $Text.Replace($escaped.Substring(1, $escaped.Length - 2), '[redacted]')
            }
        }
    }
    return $Text
}

function Save-DelegateDiagnostic {
    param([hashtable]$Capture)
    foreach ($stream in @('Stdout', 'Stderr')) {
        $text = Protect-DelegateDiagnostic $Capture[$stream].Text.ToString() $Capture.Environment
        [IO.File]::WriteAllText("$($Capture.Base).$($stream.ToLowerInvariant()).log", $text)
    }
    $summary = [ordered]@{
        Command = $Capture.Command; ProcessId = $Capture.ProcessId; Status = $Capture.Status; ExitCode = $Capture.ExitCode
        ElapsedSeconds = [math]::Round($Capture.Timer.Elapsed.TotalSeconds, 3)
        FirstOutputSeconds = $Capture.FirstOutputSeconds; LastOutputSeconds = $Capture.LastOutputSeconds
        LastEvent = $Capture.LastEvent; Events = $Capture.Events; ResultReceived = $Capture.ResultReceived
        TreeOwnership = $Capture.TreeOwnership
        ProgressReports = $Capture.ProgressReports; StdoutCharacters = $Capture.Stdout.Text.Length; StderrCharacters = $Capture.Stderr.Text.Length
    }
    [IO.File]::WriteAllText("$($Capture.Base).status.json", ($summary | ConvertTo-Json))
}

function Write-DelegateProgress {
    param([hashtable]$Capture)
    $elapsed = [math]::Round($Capture.Timer.Elapsed.TotalSeconds)
    $quiet = if ($null -eq $Capture.LastOutputSeconds) { $elapsed } else { [math]::Round($elapsed - $Capture.LastOutputSeconds) }
    $Capture.ProgressReports++
    Save-DelegateDiagnostic $Capture
    Write-Information "Delegate $($Capture.Command): ${elapsed}s elapsed; status=$($Capture.Status); events=$($Capture.Events); last=$($Capture.LastEvent); quiet=${quiet}s; diagnostics=$($Capture.Base).status.json" -InformationAction Continue
}

function Wait-DelegateOutput {
    param([hashtable]$Capture, [Threading.Tasks.Task]$Writing)
    $tasks = @($Capture.Stdout, $Capture.Stderr) | Where-Object { -not $_.Ended } | ForEach-Object { $_.Pending }
    if ($Writing) { $tasks = @($tasks) + $Writing }
    if (@($tasks).Count) { [void][Threading.Tasks.Task]::WaitAny([Threading.Tasks.Task[]]@($tasks), 100) }
    else { [Threading.Thread]::Sleep(50) }
}

function Wait-DelegateProcess {
    param($Process, [hashtable]$Capture, [switch]$ReportProgress, [double]$ProgressIntervalSeconds = 30)
    $nextReport = $ProgressIntervalSeconds
    while ($true) {
        Receive-DelegatePipe $Capture.Stdout $Capture
        Receive-DelegatePipe $Capture.Stderr $Capture
        if ($Process.HasExited) {
            if ($Capture.Job) { $Capture.Job.Dispose(); $Capture.Job = $null }
            $Capture.ExitCode = $Process.ExitCode
            if ($Capture.Stdout.Ended -and $Capture.Stderr.Ended) {
                $Capture.Status = if ($Capture.ExitCode -eq 0) { 'completed' } else { 'process_error' }
                return
            }
            $Capture.Status = 'draining'
        }
        if ($ReportProgress -and $Capture.Timer.Elapsed.TotalSeconds -ge $nextReport) {
            Write-DelegateProgress $Capture
            $nextReport = $Capture.Timer.Elapsed.TotalSeconds + $ProgressIntervalSeconds
        }
        Wait-DelegateOutput $Capture
    }
}

function Close-DelegateCapture {
    param($Process, [hashtable]$Capture)
    if ($Capture.Job) { $Capture.Job.Dispose(); $Capture.Job = $null }
    try { if (-not $Process.HasExited) { $Process.Kill($true) } }
    catch [InvalidOperationException] { if (-not $Process.HasExited) { throw } }
    Receive-DelegatePipe $Capture.Stdout $Capture
    Receive-DelegatePipe $Capture.Stderr $Capture
    if ($Process.HasExited) { $Capture.ExitCode = $Process.ExitCode }
    $Capture.Timer.Stop()
    Save-DelegateDiagnostic $Capture
}

function Send-DelegateInput {
    param($Process, [hashtable]$Capture, [string]$InputText, [switch]$ReportProgress, [double]$ProgressIntervalSeconds = 30)
    $writing = $Process.StandardInput.WriteAsync($InputText)
    $nextReport = $ProgressIntervalSeconds
    while (-not $writing.IsCompleted) {
        Receive-DelegatePipe $Capture.Stdout $Capture
        Receive-DelegatePipe $Capture.Stderr $Capture
        if ($Process.HasExited) {
            if ($Capture.Job) { $Capture.Job.Dispose(); $Capture.Job = $null }
            $Capture.Status = 'input_closed'
            throw [IO.IOException]::new("$($Capture.Command) exited before accepting its input (exit $($Process.ExitCode)). Diagnostics: $($Capture.Base).status.json")
        }
        if ($ReportProgress -and $Capture.Timer.Elapsed.TotalSeconds -ge $nextReport) {
            Write-DelegateProgress $Capture
            $nextReport = $Capture.Timer.Elapsed.TotalSeconds + $ProgressIntervalSeconds
        }
        Wait-DelegateOutput $Capture $writing
    }
    $writing.GetAwaiter().GetResult()
    $Process.StandardInput.Close()
}

function Invoke-DelegateProcess {
    [CmdletBinding()]
    param($Command, [string[]]$Arguments, [string]$Directory, [string]$InputText, [hashtable]$Environment = @{}, [switch]$ReportProgress, [double]$ProgressIntervalSeconds = 30)
    $info = New-DelegateProcessInfo $Command $Arguments $Directory $Environment
    $job = New-DelegateProcessJob
    $proc = $null
    $capture = $null
    try {
        $proc = [Diagnostics.Process]::Start($info)
        # shortcut: post-start assignment can miss an immediately spawned child; atomic creation is needed for such launchers.
        $assigned = if ($job) { $job.Attach($proc) } else { $false }
        $capture = New-DelegateCapture $proc $Command $Environment
        $capture.Job = $job
        if ($job) { $capture.TreeOwnership = if ($assigned) { 'windows-job' } else { 'root-exited-before-job' } }
        Save-DelegateDiagnostic $capture
        if ($ReportProgress) { Write-Information "Delegate $($Command.Name) started; diagnostics=$($capture.Base).status.json" -InformationAction Continue }
        Send-DelegateInput $proc $capture $InputText -ReportProgress:$ReportProgress -ProgressIntervalSeconds $ProgressIntervalSeconds
        Wait-DelegateProcess $proc $capture -ReportProgress:$ReportProgress -ProgressIntervalSeconds $ProgressIntervalSeconds
        return @{ ExitCode = $proc.ExitCode; Output = $capture.Stdout.Text.ToString(); Error = $capture.Stderr.Text.ToString(); Diagnostics = "$($capture.Base).status.json" }
    } catch {
        if ($capture) {
            if ($capture.Status -in @('running', 'draining') -and $_.Exception -isnot [System.Management.Automation.PipelineStoppedException]) {
                $capture.Status = 'failed'
            }
            $_.Exception.Data['DiagnosticsDirectory'] = $script:DelegateLogDirectory
            $_.Exception.Data['Diagnostics'] = "$($capture.Base).status.json"
        }
        throw
    } finally {
        try {
            if ($capture) {
                if ($capture.Status -in @('running', 'draining')) { $capture.Status = 'cancelled' }
                Close-DelegateCapture $proc $capture
            }
            elseif ($proc -and -not $proc.HasExited) { $proc.Kill($true) }
        } finally {
            if ($job) { $job.Dispose() }
            if ($proc) { $proc.Dispose() }
        }
    }
}
