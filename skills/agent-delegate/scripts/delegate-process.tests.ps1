# Verifies real pipe handling, deadline cleanup, progress, and diagnostic redaction without inference.
param([switch]$IncludeSlowInput)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/delegate-process.ps1"
$testRoot = [IO.Directory]::CreateTempSubdirectory('delegate-process-tests-').FullName
$script:DelegateLogDirectory = Join-Path $testRoot 'logs'
$null = [IO.Directory]::CreateDirectory($script:DelegateLogDirectory)
$shell = [pscustomobject]@{ Name = 'synthetic-agent'; Source = (Get-Process -Id $PID).Path }
$TimeoutSeconds = 5
$passed = 0

function Invoke-Fixture {
    [CmdletBinding()]
    param([string]$Body, [string]$InputText = '', [hashtable]$Environment = @{}, [switch]$Progress)
    $path = Join-Path $testRoot ('child-' + [Guid]::NewGuid().ToString('N') + '.ps1')
    [IO.File]::WriteAllText($path, '[Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)' + "`n" + $Body)
    Invoke-DelegateProcess $shell @('-NoProfile', '-File', $path) $testRoot $InputText $Environment -ReportProgress:$Progress -ProgressIntervalSeconds 0.2
}

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$inputText = "Neutral input: ✓`nSecond line"
$result = Invoke-Fixture '[Console]::Out.Write([Console]::In.ReadToEnd()); [Console]::Error.Write("stderr tail")' $inputText
Assert-Condition ($result.Output.TrimEnd() -ceq $inputText -and $result.Error.TrimEnd() -eq 'stderr tail') 'Unicode or unterminated pipe output was lost'
$status = Get-Content -LiteralPath $result.Diagnostics -Raw | ConvertFrom-Json
Assert-Condition ($status.Status -eq 'completed' -and $status.ExitCode -eq 0) 'Successful exit diagnostics were incorrect'
$passed++

$result = Invoke-Fixture '[Console]::In.ReadToEnd() | Out-Null; [Console]::Out.Write($env:SYNTHETIC_TOKEN); [Console]::Error.Write($env:SYNTHETIC_BASE_URL); exit 7' '' @{
    SYNTHETIC_TOKEN = 'synthetic-private-credential'; SYNTHETIC_BASE_URL = 'https://endpoint.invalid?key=synthetic-private-query'
}
$logs = [IO.File]::ReadAllText($result.Diagnostics.Replace('.status.json', '.stdout.log')) + [IO.File]::ReadAllText($result.Diagnostics.Replace('.status.json', '.stderr.log'))
Assert-Condition ($logs -notmatch 'synthetic-private-' -and $logs -match '\[redacted\]') 'Saved diagnostics exposed configured secrets'
Assert-Condition ($result.ExitCode -eq 7) 'Nonzero process exit was lost'
$passed++

$result = Invoke-Fixture '[Console]::In.ReadToEnd() | Out-Null; $headers=$env:SYNTHETIC_HEADERS -split "`n"; [Console]::Error.WriteLine($headers[0]); [Console]::Out.WriteLine($headers[1]); [Console]::Out.Write(''paired-secret-one'')' '' @{
    SYNTHETIC_HEADERS = "Authorization: Bearer paired-secret-one`nX-Other: paired-secret-two"
}
$logs = [IO.File]::ReadAllText($result.Diagnostics.Replace('.status.json', '.stdout.log')) + [IO.File]::ReadAllText($result.Diagnostics.Replace('.status.json', '.stderr.log'))
Assert-Condition ($logs -notmatch 'paired-secret-one|paired-secret-two') 'An individual custom header or authentication value escaped redaction'
$passed++

$events = @()
$result = Invoke-Fixture '[Console]::In.ReadToEnd() | Out-Null; [Console]::Out.WriteLine(''{"type":"system","subtype":"init"}''); [Console]::Out.Flush(); Start-Sleep -Milliseconds 650; [Console]::Out.WriteLine(''{"type":"result","result":"neutral"}'')' -Progress -InformationVariable events 6>$null
$status = Get-Content -LiteralPath $result.Diagnostics -Raw | ConvertFrom-Json
Assert-Condition ($status.Events -eq 2 -and $status.ResultReceived -and $status.ProgressReports -gt 0) 'Streaming progress or final-event detection was lost'
Assert-Condition (@($events | Where-Object { $_.MessageData -match 'elapsed;' }).Count -gt 0) 'Progress did not reach the information stream'
$passed++

$TimeoutSeconds = 0.8
$caught = $null
try { Invoke-Fixture '[Console]::In.ReadToEnd() | Out-Null; Start-Sleep -Seconds 20' | Out-Null } catch { $caught = $_.Exception }
Assert-Condition ($null -ne $caught -and $caught.Data['Diagnostics']) 'Timeout discarded its diagnostics path'
$status = Get-Content -LiteralPath $caught.Data['Diagnostics'] -Raw | ConvertFrom-Json
Assert-Condition ($status.Status -eq 'timed_out' -and $null -eq $status.FirstOutputSeconds) 'A silent timeout could not be distinguished from active output'
Assert-Condition ($null -eq (Get-Process -Id $status.ProcessId -ErrorAction SilentlyContinue)) 'Timed-out child process survived'
$passed++

$TimeoutSeconds = 1.2
$caught = $null
$active = '[Console]::In.ReadToEnd() | Out-Null; [Console]::Out.WriteLine(''{"type":"system","subtype":"init"}''); [Console]::Out.Flush(); [Console]::Error.Write("unfinished stderr"); [Console]::Error.Flush(); while ($true) { [Console]::Out.WriteLine(''{"type":"stream_event","event":{"type":"content_block_delta"}}''); [Console]::Out.Flush(); Start-Sleep -Milliseconds 100 }'
try { Invoke-Fixture $active -Progress 6>$null | Out-Null } catch { $caught = $_.Exception }
Assert-Condition ($null -ne $caught -and $caught.Data['Diagnostics']) 'An active child escaped the total deadline'
$status = Get-Content -LiteralPath $caught.Data['Diagnostics'] -Raw | ConvertFrom-Json
$stderr = [IO.File]::ReadAllText($caught.Data['Diagnostics'].Replace('.status.json', '.stderr.log'))
Assert-Condition ($status.Status -eq 'timed_out' -and $status.Events -gt 1 -and $status.ElapsedSeconds -lt 4) 'Activity incorrectly extended the hard deadline'
Assert-Condition ($stderr -match 'unfinished stderr') 'Unterminated diagnostic output vanished on timeout'
$passed++

$TimeoutSeconds = 5
$flood = '[Console]::Out.WriteLine((''x'' * 4096)); for ($i=0; $i -lt 512; $i++) { [Console]::Out.WriteLine((''x'' * 4096)) }; [Console]::Out.Flush(); $inputText=[Console]::In.ReadToEnd(); [Console]::Error.Write($inputText.Length)'
$result = Invoke-Fixture $flood ('n' * 200000)
Assert-Condition ($result.Output.Length -gt 2000000 -and $result.Error.Trim() -eq '200000') 'Simultaneous stdin and stdout caused a pipe deadlock'
$passed++

$TimeoutSeconds = 0.8
$caught = $null
try { Invoke-Fixture 'Start-Sleep -Seconds 20' ('n' * 2000000) | Out-Null } catch { $caught = $_.Exception }
Assert-Condition ($null -ne $caught -and $caught.Data['Diagnostics']) 'A child refusing input escaped the deadline'
$status = Get-Content -LiteralPath $caught.Data['Diagnostics'] -Raw | ConvertFrom-Json
Assert-Condition ($status.Status -eq 'input_timeout' -and $status.ElapsedSeconds -lt 4) 'Blocked stdin ignored the task deadline'
$passed++

if ($IsWindows) {
    $TimeoutSeconds = 5
    $descendant = Join-Path $testRoot 'owned-descendant.ps1'
    $pidFile = Join-Path $testRoot 'owned-descendant.pid'
    [IO.File]::WriteAllText($descendant, 'Start-Sleep -Seconds 20')
    $spawn = @'
[Console]::In.ReadToEnd() | Out-Null
$info = [Diagnostics.ProcessStartInfo]::new()
$info.FileName = (Get-Process -Id $PID).Path
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
foreach ($argument in @('-NoProfile', '-File', $env:SYNTHETIC_DESCENDANT)) { $info.ArgumentList.Add($argument) }
$child = [Diagnostics.Process]::Start($info)
[IO.File]::WriteAllText($env:SYNTHETIC_PID_FILE, [string]$child.Id)
'@
    $result = Invoke-Fixture $spawn '' @{ SYNTHETIC_DESCENDANT = $descendant; SYNTHETIC_PID_FILE = $pidFile }
    $childId = [int][IO.File]::ReadAllText($pidFile)
    $survivor = Get-Process -Id $childId -ErrorAction SilentlyContinue
    if ($survivor) {
        $owner = Get-CimInstance Win32_Process -Filter "ProcessId=$childId"
        if ($owner.CommandLine.Contains($descendant)) { $survivor.Kill($true) }
        throw 'A descendant survived its completed owner'
    }
    $status = Get-Content -LiteralPath $result.Diagnostics -Raw | ConvertFrom-Json
    Assert-Condition ($status.Status -eq 'completed' -and $status.TreeOwnership -eq 'windows-job') 'Windows process ownership was not established'
    $passed++
    $caught = $null
    try {
        Invoke-Fixture ($spawn.Replace('[Console]::In.ReadToEnd() | Out-Null', '')) ('n' * 200000) @{
            SYNTHETIC_DESCENDANT = $descendant; SYNTHETIC_PID_FILE = $pidFile
        } | Out-Null
    } catch { $caught = $_.Exception }
    Assert-Condition ($null -ne $caught -and $caught.Data['Diagnostics']) 'An exited input owner left a blocked writer without diagnostics'
    $status = Get-Content -LiteralPath $caught.Data['Diagnostics'] -Raw | ConvertFrom-Json
    Assert-Condition ($status.Status -eq 'input_closed' -and $status.ElapsedSeconds -lt 3) 'Input delivery waited for the deadline after its owner exited'
    $childId = [int][IO.File]::ReadAllText($pidFile)
    Assert-Condition ($null -eq (Get-Process -Id $childId -ErrorAction SilentlyContinue)) 'An exited input owner left its descendant alive'
    $passed++
}

if ($IncludeSlowInput) {
    $TimeoutSeconds = 45
    $result = Invoke-Fixture 'Start-Sleep -Seconds 31; [Console]::In.ReadToEnd() | Out-Null; [Console]::Out.Write("accepted")' ('n' * 200000) -Progress 6>$null
    $status = Get-Content -LiteralPath $result.Diagnostics -Raw | ConvertFrom-Json
    Assert-Condition ($result.Output -eq 'accepted' -and $status.ElapsedSeconds -ge 30 -and $status.ElapsedSeconds -lt 45) 'Input delivery was cut short before the configured deadline'
    Assert-Condition ($status.ProgressReports -gt 0) 'Input delivery stalled without progress reporting'
    $passed++
}

[pscustomobject]@{ passed = $passed; externalInferenceRequests = 0; diagnostics = $script:DelegateLogDirectory } | ConvertTo-Json -Compress
