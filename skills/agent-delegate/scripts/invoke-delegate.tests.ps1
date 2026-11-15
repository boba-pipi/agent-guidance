# Exercises provider routing and review verification with an isolated fake CLI.
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'invoke-delegate.ps1'
$testRoot = [IO.Directory]::CreateTempSubdirectory('review-route-test-').FullName
$savedEnvironment = @{}
$testCount = 0
$routingPattern = '^(ANTHROPIC_|AWS_|GOOGLE_|AZURE_|CLOUD_ML_REGION$|CLAUDE_CODE_(USE_(BEDROCK|VERTEX|FOUNDRY)|EFFORT_LEVEL)$)'
foreach ($entry in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()) {
    if ($entry.Key -match $routingPattern -or $entry.Key -in @('CLAUDE_CONFIG_DIR', 'PATH', 'REVIEW_MOCK_MODE')) {
        $savedEnvironment[$entry.Key] = $entry.Value
    }
}

function Assert-Value {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -cne $Expected) { throw $Message }
}

function Add-FakeCli {
    param([string]$Name, [string]$Content)
    $Content = '[Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)' + "`n" + $Content
    if ($IsWindows) {
        [IO.File]::WriteAllText((Join-Path $testRoot "$Name.ps1"), $Content)
    } else {
        $path = Join-Path $testRoot $Name
        [IO.File]::WriteAllText($path, "#!/usr/bin/env pwsh`n$Content")
        chmod +x $path
        if ($LASTEXITCODE -ne 0) { throw "Could not prepare $Name fixture." }
    }
}

function Set-Fixture {
    param([hashtable]$Settings = @{}, [hashtable]$Environment = @{})
    foreach ($name in @([Environment]::GetEnvironmentVariables('Process').Keys)) {
        if ($name -match $routingPattern) { Remove-Item -LiteralPath "Env:$name" }
    }
    $env:CLAUDE_CONFIG_DIR = $testRoot
    foreach ($name in $Environment.Keys) { [Environment]::SetEnvironmentVariable($name, $Environment[$name], 'Process') }
    [IO.File]::WriteAllText((Join-Path $testRoot 'settings.json'), ($Settings | ConvertTo-Json -Depth 8))
}

function Test-Route {
    param([hashtable]$Settings, [hashtable]$Environment, [hashtable]$Expected)
    Set-Fixture $Settings $Environment
    $route = & $runner -From codex -InspectRoute | ConvertFrom-Json
    foreach ($key in $Expected.Keys) { Assert-Value $route.$key $Expected[$key] "Route case $script:testCount field $key was '$($route.$key)', expected '$($Expected[$key])'" }
    Assert-Value ($route.PSObject.Properties.Name -contains 'Environment') $false 'Inspection exposed credential-bearing environment'
    $script:testCount++
}

function Test-Failure {
    param([scriptblock]$Action, [string]$Pattern)
    $caught = $false
    try { & $Action | Out-Null }
    catch {
        $caught = $true
        if ($_.Exception.Message -notmatch $Pattern) { throw 'Failure did not identify the expected condition' }
        if ($_.Exception.Message -match 'synthetic-provider-token|synthetic-query-secret') { throw 'Failure leaked a provider credential or endpoint query' }
    }
    Assert-Value $caught $true 'Invalid configuration or review was accepted'
    $script:testCount++
}

function Invoke-MockReview {
    param([string]$Mode = 'ok', [string]$ReviewDirectory)
    Set-Fixture @{ env = @{
        ANTHROPIC_BASE_URL = 'https://gateway.invalid/anthropic?key=synthetic-query-secret'
        ANTHROPIC_MODEL = 'deepseek-flash[1M]'
        ANTHROPIC_AUTH_TOKEN = 'synthetic-provider-token'
        CLAUDE_CODE_EFFORT_LEVEL = 'max'
    } }
    $env:REVIEW_MOCK_MODE = $Mode
    return & $runner -From codex -Mode review -PromptPath (Join-Path $testRoot 'packet.txt') -ReviewDirectory $ReviewDirectory
}

try {
    Test-Route @{} @{} @{ Provider = 'anthropic'; EndpointHost = 'api.anthropic.com'; Authentication = 'claude-account'; Model = $null; Effort = 'xhigh' }
    Test-Route @{} @{ ANTHROPIC_BASE_URL = 'https://api.anthropic.com'; ANTHROPIC_API_KEY = 'synthetic-key' } @{ Provider = 'anthropic'; Authentication = 'api-credentials' }
    Test-Route @{} @{ ANTHROPIC_BASE_URL = 'https://api.deepseek.com/anthropic'; ANTHROPIC_MODEL = 'deepseek-flash[1M]' } @{ Provider = 'compatible'; EndpointHost = 'api.deepseek.com'; Model = 'deepseek-flash[1M]'; ModelSource = 'process'; Authentication = 'provider-credentials' }
    Test-Route @{ env = @{ ANTHROPIC_BASE_URL = 'https://gateway.invalid'; ANTHROPIC_MODEL = 'configured-model'; CLAUDE_CODE_EFFORT_LEVEL = 'max' } } @{} @{ Provider = 'compatible'; Model = 'configured-model'; ModelSource = 'user-settings.env'; Effort = 'max' }
    Test-Route @{ env = @{ ANTHROPIC_MODEL = 'file-model' } } @{ ANTHROPIC_MODEL = 'process-model' } @{ Model = 'process-model'; ModelSource = 'process' }
    Test-Route @{ model = 'saved-model'; env = @{ ANTHROPIC_BASE_URL = 'https://gateway.invalid' } } @{} @{ Model = 'saved-model'; ModelSource = 'user-settings.model'; Provider = 'compatible' }
    Test-Route @{} @{ ANTHROPIC_BASE_URL = 'https://gateway.invalid'; ANTHROPIC_MODEL = 'claude-native-looking-model' } @{ Provider = 'compatible'; Model = 'claude-native-looking-model' }
    Test-Route @{} @{ ANTHROPIC_BASE_URL = 'https://api.anthropic.com.example.invalid' } @{ Provider = 'compatible'; EndpointHost = 'api.anthropic.com.example.invalid' }
    Test-Route @{} @{ ANTHROPIC_BASE_URL = 'http://api.anthropic.com' } @{ Provider = 'compatible' }
    foreach ($cloud in @('BEDROCK', 'VERTEX', 'FOUNDRY')) {
        Test-Route @{} @{ "CLAUDE_CODE_USE_$cloud" = '1'; ANTHROPIC_MODEL = 'cloud-model' } @{ Provider = $cloud.ToLowerInvariant(); Model = 'cloud-model'; Authentication = 'provider-credentials' }
    }
    Test-Route @{} @{ CLAUDE_CODE_USE_BEDROCK = '0' } @{ Provider = 'anthropic' }
    Test-Route @{} @{ ANTHROPIC_MODEL = 'fable'; ANTHROPIC_DEFAULT_FABLE_MODEL = 'mapped-model[1M]' } @{ Model = 'mapped-model[1M]' }
    Test-Route @{} @{ ANTHROPIC_MODEL = 'fable[1M]'; ANTHROPIC_DEFAULT_FABLE_MODEL = 'mapped-model' } @{ Model = 'mapped-model[1M]' }
    Set-Fixture @{} @{ ANTHROPIC_MODEL = 'configured-model' }
    $override = & $runner -From codex -InspectRoute -Model 'explicit-model' -Effort max | ConvertFrom-Json
    Assert-Value $override.Model 'explicit-model' 'Explicit model override was ignored'
    Assert-Value $override.Effort 'max' 'Explicit effort override was ignored'
    $testCount++
    $override = & $runner -From codex -InspectRoute -Effort high | ConvertFrom-Json
    Assert-Value $override.Effort 'high' 'Explicit user effort exception was overridden'
    $testCount++
    Set-Fixture @{} @{ ANTHROPIC_BASE_URL = 'invalid-synthetic-url' }
    Test-Failure { & $runner -From codex -InspectRoute } 'ANTHROPIC_BASE_URL'
    Set-Fixture
    Test-Failure { & $runner -From codex -PromptPath 'unused' } 'No delegated model is configured'

    [IO.File]::WriteAllText((Join-Path $testRoot 'packet.txt'), 'Neutral synthetic review packet.')
    $fakeCLI = @'
$instruction = [Console]::In.ReadToEnd()
$model = $args[[Array]::IndexOf($args, '--model') + 1]
$effort = $args[[Array]::IndexOf($args, '--effort') + 1]
if ($effort -ne $env:CLAUDE_CODE_EFFORT_LEVEL) { throw 'Effort flag and child environment differ' }
foreach ($required in @('--print', '--restricted', '--strict-mcp-config', '--verbose', '--no-session-persistence')) {
    if ([Array]::IndexOf($args, $required) -lt 0) { throw 'Evidence confinement was not enabled' }
}
$toolsArg = $args[[Array]::IndexOf($args, '--tools') + 1]
if ($toolsArg -eq 'Read,Glob,Grep,Edit,Write') {
    if ($args -notcontains 'acceptEdits' -or $args -notcontains 'none' -or $instruction -notmatch 'isolated checkout') { throw 'Expected scoped Claude edits' }
    if ([IO.File]::ReadAllText((Join-Path ([Environment]::CurrentDirectory) 'tracked.txt')) -ne 'committed') { throw 'Wrong source baseline' }
    [IO.File]::WriteAllText((Join-Path ([Environment]::CurrentDirectory) 'tracked.txt'), 'claude edit')
    $actual = $model -replace '(?i)\[1m\]$', ''
    $events = @(
        @{ type = 'system'; subtype = 'init'; model = $actual; tools = ($toolsArg -split ','); mcp_servers = @() }
        @{ type = 'result'; result = 'Synthetic Claude code completed.'; is_error = $false; modelUsage = @{ $actual = @{ canonicalModel = $actual } } }
    )
    $events | ForEach-Object { ConvertTo-Json -InputObject $_ -Depth 10 -Compress }
    exit
}
$expectedArguments = @{ '--tools' = 'Read,Glob,Grep'; '--output-format' = 'stream-json' }
foreach ($name in $expectedArguments.Keys) {
    $index = [Array]::IndexOf($args, $name)
    if ($index -lt 0 -or $args[$index + 1] -ne $expectedArguments[$name]) { throw 'Native CLI argument changed' }
}
foreach ($removed in @('--max-turns', '--safe-mode', '--setting-sources', '--system-prompt')) {
    if ([Array]::IndexOf($args, $removed) -ge 0) { throw 'The native review workflow was overridden' }
}
if ($instruction -notmatch '^Read (review-request-[a-f0-9]+\.txt)') { throw 'Evidence read instruction is missing' }
$requestName = $Matches[1]
if ($instruction -notmatch 'counterexamples' -or $instruction -notmatch 'measured baseline') { throw 'Adversarial review criteria are missing' }
if (-not (Test-Path -LiteralPath $requestName)) { throw 'Curated request file is unavailable' }
if ([IO.File]::ReadAllText((Join-Path ([Environment]::CurrentDirectory) $requestName)) -cne [IO.File]::ReadAllText((Join-Path $env:CLAUDE_CONFIG_DIR 'packet.txt'))) { throw 'Review request content changed' }
[IO.File]::WriteAllText((Join-Path $env:CLAUDE_CONFIG_DIR 'last-review-directory.txt'), [Environment]::CurrentDirectory)
$actual = $model -replace '(?i)\[1m\]$', ''
if ($env:REVIEW_MOCK_MODE -eq 'mismatch') { $actual = 'unexpected-model' }
$sessionModel = $model -replace '(?i)\[1m\]$', ''
if ($env:REVIEW_MOCK_MODE -eq 'session-mismatch') { $sessionModel = 'unexpected-model' }
$tools = @('Read', 'Glob', 'Grep')
$servers = @()
if ($env:REVIEW_MOCK_MODE -eq 'tools') { $tools += 'Bash' }
if ($env:REVIEW_MOCK_MODE -eq 'mcp') { $servers = @('unexpected-server') }
$events = @(@{ type = 'system'; subtype = 'init'; model = $sessionModel; tools = $tools; mcp_servers = $servers })
if ($env:REVIEW_MOCK_MODE -ne 'unread') {
    $events += @{ type = 'assistant'; message = @{ content = @(@{ type = 'tool_use'; id = 'evidence-read'; name = 'Read'; input = @{ file_path = $requestName } }) } }
    $events += @{ type = 'user'; message = @{ content = @(@{ type = 'tool_result'; tool_use_id = 'evidence-read'; content = 'Neutral evidence'; is_error = $false }) } }
}
if ($env:REVIEW_MOCK_MODE -eq 'unresolved-read') {
    $events += @{ type = 'assistant'; message = @{ content = @(@{ type = 'tool_use'; id = 'unresolved-read'; name = 'Read'; input = @{ file_path = $requestName } }) } }
}
$credentialPresent = $env:ANTHROPIC_AUTH_TOKEN -eq 'synthetic-provider-token'
$verdict = @{ model = $model; effort = $effort; credentialPresent = $credentialPresent; workingDirectory = [Environment]::CurrentDirectory } | ConvertTo-Json -Compress
$isError = $env:REVIEW_MOCK_MODE -eq 'auth'
if ($isError) { $verdict = "Synthetic configured-provider authentication failed with HTTP 401 $env:ANTHROPIC_AUTH_TOKEN $env:ANTHROPIC_BASE_URL" }
if ($env:REVIEW_MOCK_MODE -eq 'raw-tool') { $verdict = '<｜｜DSML｜｜ calls><｜｜DSML｜｜ invoke name="Bash">synthetic</｜｜DSML｜｜ invoke></｜｜DSML｜｜ calls>' }
if ($env:REVIEW_MOCK_MODE -eq 'empty') { $verdict = '   ' }
if ($env:REVIEW_MOCK_MODE -in @('structured-tool', 'denied-tool')) {
    $events += @{ type = 'assistant'; message = @{ content = @(@{ type = 'tool_use'; id = 'outside-call'; name = 'Bash'; input = @{ command = 'echo synthetic' } }) } }
    if ($env:REVIEW_MOCK_MODE -eq 'denied-tool') {
        $events += @{ type = 'user'; message = @{ content = @(@{ type = 'tool_result'; tool_use_id = 'outside-call'; is_error = $true; content = 'Tool unavailable' }) } }
    }
}
$events += @{ type = 'result'; result = $verdict; is_error = $isError; modelUsage = @{ $actual = @{ canonicalModel = $actual } } }
$events | ForEach-Object { ConvertTo-Json -InputObject $_ -Depth 10 -Compress }
'@
    Add-FakeCli 'claude' $fakeCLI
    $env:PATH = $testRoot + [IO.Path]::PathSeparator + $savedEnvironment.PATH
    $result = @(Invoke-MockReview)
    $verdict = $result[-1] | ConvertFrom-Json
    Assert-Value $verdict.model 'deepseek-flash[1M]' 'Configured context qualifier was lost'
    Assert-Value $verdict.effort 'max' 'Eligible configured effort was lost'
    Assert-Value $verdict.credentialPresent $true 'User-settings credentials did not reach the child'
    Assert-Value (($result -join "`n").Contains('synthetic-provider-token')) $false 'Output leaked a provider credential'
    Assert-Value (($result -join "`n").Contains('synthetic-query-secret')) $false 'Output leaked an endpoint query'
    Assert-Value (Test-Path -LiteralPath $verdict.workingDirectory) $false 'Owned temporary evidence directory survived success'
    $testCount++
    Test-Failure { Invoke-MockReview 'mismatch' } 'model did not match'
    Test-Failure { Invoke-MockReview 'session-mismatch' } 'model did not match'
    Test-Failure { Invoke-MockReview 'tools' } 'outside the delegated file scope'
    Test-Failure { Invoke-MockReview 'mcp' } 'outside the delegated file scope'
    Test-Failure { Invoke-MockReview 'auth' } 'configured-provider authentication failed'
    Test-Failure { Invoke-MockReview 'raw-tool' } 'tool request instead of a review verdict'
    Test-Failure { Invoke-MockReview 'structured-tool' } 'unresolved'
    Test-Failure { Invoke-MockReview 'empty' } 'did not complete'
    Test-Failure { Invoke-MockReview 'unread' } 'did not inspect'
    Test-Failure { Invoke-MockReview 'unresolved-read' } 'unresolved'
    $failedDirectory = [IO.File]::ReadAllText((Join-Path $testRoot 'last-review-directory.txt'))
    Assert-Value (Test-Path -LiteralPath $failedDirectory) $false 'Owned temporary evidence directory survived failure'
    $deniedResult = @(Invoke-MockReview 'denied-tool')
    Assert-Value (($deniedResult[-1] | ConvertFrom-Json).credentialPresent) $true 'Denied request prevented a valid read-only verdict'
    $testCount++
    $curated = Join-Path $testRoot 'curated'
    $null = [IO.Directory]::CreateDirectory($curated)
    $sentinel = Join-Path $curated 'caller-evidence.txt'
    [IO.File]::WriteAllText($sentinel, 'Caller-owned synthetic evidence.')
    $curatedResult = @(Invoke-MockReview 'ok' $curated)
    Assert-Value (Test-Path -LiteralPath $curated -PathType Container) $true 'Caller evidence directory was removed'
    Assert-Value ((($curatedResult[-1] | ConvertFrom-Json).workingDirectory).TrimEnd('\')) ($curated.TrimEnd('\')) 'Review did not use the curated directory'
    Assert-Value ([IO.Directory]::GetFileSystemEntries($curated).Length) 1 'Generated request survived in caller evidence directory'
    Assert-Value ([IO.File]::ReadAllText($sentinel)) 'Caller-owned synthetic evidence.' 'Caller evidence file was modified or removed'
    $testCount++
    Test-Failure { Invoke-MockReview 'ok' (Join-Path $testRoot 'missing-directory') } 'ReviewDirectory must contain'
    $fakeCodex = @'
if ($args[0] -eq 'debug') {
    @{ models = @(@{ slug = 'gpt-6.1-sol'; visibility = 'list'; supported_reasoning_levels = @(@{ effort = 'xhigh' }, @{ effort = 'max' }) }) } | ConvertTo-Json -Depth 8 -Compress
    exit
}
$request = [Console]::In.ReadToEnd()
$index = [Array]::IndexOf($args, '-s')
$sandbox = $args[$index + 1]
if ($sandbox -eq 'workspace-write') {
    if ($request -notmatch 'isolated checkout' -or -not (Test-Path -LiteralPath 'tracked.txt')) { throw 'Expected code task in a populated snapshot' }
    if ($args -notcontains 'sandbox_workspace_write.network_access=false' -or $args -notcontains 'sandbox_workspace_write.exclude_slash_tmp=true') { throw 'Code sandbox grants extra access' }
    [IO.File]::WriteAllText((Join-Path ([Environment]::CurrentDirectory) 'tracked.txt'), 'edited')
    [IO.File]::WriteAllText((Join-Path ([Environment]::CurrentDirectory) 'added.txt'), 'added')
    @{ type = 'item.completed'; item = @{ type = 'command_execution'; command = 'synthetic verification'; exit_code = 0; status = 'completed' } } | ConvertTo-Json -Depth 6 -Compress
    $response = 'Synthetic Codex code completed.'
} elseif ($request -match 'Interpret the recorded test execution') {
    if ($request -notmatch 'Exit code: 7' -or $request -notmatch 'synthetic failure') { throw 'Expected observed test result' }
    if (Test-Path -LiteralPath 'tracked.txt') { throw 'The test analyst can see source files' }
    $response = 'Synthetic Codex test analysis completed.'
} else {
    if ($sandbox -ne 'read-only' -or $args -notcontains 'shell_tool' -or $request -notmatch 'counterexamples' -or $request -notmatch 'Neutral synthetic') { throw 'Expected a packet-only adversarial review' }
    $response = 'Synthetic Codex review completed.'
}
@{ type = 'item.completed'; item = @{ type = 'agent_message'; text = $response } } | ConvertTo-Json -Depth 6 -Compress
@{ type = 'turn.completed' } | ConvertTo-Json -Compress
'@
    Add-FakeCli 'codex' $fakeCodex
    $packet = Join-Path $testRoot 'packet.txt'
    $codexResult = @(& $runner -From claude -PromptPath $packet)
    Assert-Value $codexResult[-1] 'Synthetic Codex review completed.' 'Codex review compatibility regressed'
    $testCount++
    Test-Failure { & $runner -From claude -PromptPath $packet -Model 'unsupported-model' } 'does not advertise'
    Test-Failure { & $runner -From claude -PromptPath $packet -ReviewDirectory $curated } 'Include Codex review evidence in -PromptPath'

    $repo = [IO.Directory]::CreateDirectory((Join-Path $testRoot 'repo with spaces')).FullName
    git -C $repo init --quiet --template=
    [IO.File]::WriteAllText((Join-Path $repo 'tracked.txt'), 'committed')
    git -C $repo add -- tracked.txt
    git -C $repo -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m Fixture
    if ($LASTEXITCODE -ne 0) { throw 'Could not commit the test fixture.' }
    [IO.File]::WriteAllText((Join-Path $repo 'tracked.txt'), 'local uncommitted edit')
    $code = & $runner -From claude -Mode code -Repository $repo -PromptPath $packet | ConvertFrom-Json
    Assert-Value $code.Summary 'Synthetic Codex code completed.' 'Wrong code mode result'
    Assert-Value ($code.Diff -match '\+edited' -and $code.Diff -match '\+added') $true 'Code diff lost edits or added files'
    Assert-Value ([IO.File]::ReadAllText((Join-Path $repo 'tracked.txt'))) 'local uncommitted edit' 'Code overwrote the caller checkout'
    Assert-Value $code.AgentCommands[0].exit_code 0 'The sandboxed verification exit code was lost'
    $claudeCode = & $runner -From codex -Mode code -Repository $repo -PromptPath $packet | ConvertFrom-Json
    Assert-Value $claudeCode.Summary 'Synthetic Claude code completed.' 'Wrong Claude code mode result'
    Assert-Value ($claudeCode.Diff -match '\+claude edit') $true 'Claude edit was missing from the diff'
    $testCount++

    $shell = (Get-Process -Id $PID).Path
    $testCommand = ConvertTo-Json -InputObject @($shell, '-NoProfile', '-Command', "[Console]::Error.WriteLine('synthetic failure'); exit 7") -Compress
    $test = & $runner -From claude -Mode test -Repository $repo -PromptPath $packet -TestCommandJson $testCommand | ConvertFrom-Json
    Assert-Value $test.Test.ExitCode 7 'Test process exit status was lost'
    Assert-Value $test.Summary 'Synthetic Codex test analysis completed.' 'Wrong test mode result'
    Assert-Value ([IO.File]::ReadAllText((Join-Path $test.Checkout 'tracked.txt'))) 'committed' 'Test used unstaged source'
    $testCount++
    $writes = ConvertTo-Json -InputObject @($shell, '-NoProfile', '-Command', "[IO.File]::WriteAllText('tracked.txt', 'unexpected edit')") -Compress
    Test-Failure { & $runner -From claude -Mode test -Repository $repo -PromptPath $packet -TestCommandJson $writes } 'test changed tracked files'
    Test-Failure { & $runner -From claude -Mode test -Repository $repo -PromptPath $packet -TestCommandJson '"pwsh"' } 'must be an array'
    [pscustomobject]@{ passed = $testCount; externalInferenceRequests = 0 } | ConvertTo-Json -Compress
} finally {
    foreach ($name in @([Environment]::GetEnvironmentVariables('Process').Keys)) {
        if ($name -match $routingPattern -or $name -in @('CLAUDE_CONFIG_DIR', 'PATH', 'REVIEW_MOCK_MODE')) {
            Remove-Item -LiteralPath "Env:$name"
        }
    }
    foreach ($name in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process') }
}
