#Requires -Version 7.0
param(
    [string] $TargetHome = $HOME
)

$ErrorActionPreference = 'Stop'
$repository = Split-Path -Parent $PSScriptRoot
$upstreamSkills = @(
    'upstream/mattpocock-skills/skills/engineering/codebase-design'
    'upstream/mattpocock-skills/skills/engineering/diagnosing-bugs'
    'upstream/mattpocock-skills/skills/productivity/grill-me'
    'upstream/mattpocock-skills/skills/productivity/grilling'
    'upstream/ponytail/skills/ponytail'
    'upstream/application-performance/skills/performance-optimization'
    'upstream/perf-engineering/perf-engineering'
)
$repositories = @($upstreamSkills | ForEach-Object {
    ($_.Split('/') | Select-Object -First 2) -join '/'
} | Sort-Object -Unique)

git -C $repository submodule update --init --checkout --depth 1 -- @repositories
if ($LASTEXITCODE -ne 0) { throw 'Could not fetch the pinned upstream skills.' }
foreach ($modulePath in $repositories) {
    $pending = @(git -C (Join-Path $repository $modulePath) status --porcelain)
    if ($LASTEXITCODE -ne 0 -or $pending.Count) {
        throw "Resolve the local changes in $modulePath before installing."
    }
}

$sources = @(Get-ChildItem -LiteralPath (Join-Path $repository 'skills') -Directory)
$sources += @($upstreamSkills | ForEach-Object {
    Get-Item -LiteralPath (Join-Path $repository $_)
})
foreach ($source in $sources) {
    if (-not (Test-Path -LiteralPath (Join-Path $source.FullName 'SKILL.md') -PathType Leaf)) {
        throw "Missing SKILL.md in $($source.FullName)."
    }
}

function Publish-SkillBundle {
    param([string] $Store, [System.IO.DirectoryInfo[]] $Sources)

    $staging = [IO.Directory]::CreateDirectory(
        (Join-Path $Store ("install-" + [guid]::NewGuid()))
    ).FullName
    $incoming = [IO.Directory]::CreateDirectory((Join-Path $staging 'incoming')).FullName
    $previous = Join-Path $staging 'previous'
    $current = Join-Path $Store 'skills'
    try {
        foreach ($source in $Sources) {
            $destination = Join-Path $incoming $source.Name
            if (Test-Path -LiteralPath $destination) { throw "Duplicate skill: $($source.Name)" }
            Copy-Item -LiteralPath $source.FullName -Destination $destination -Recurse
        }
        $existing = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($existing) {
            if (-not $existing.PSIsContainer -or $existing.LinkType) {
                throw "Expected a regular bundle directory at $current."
            }
            [IO.Directory]::Move($current, $previous)
        }
        try {
            [IO.Directory]::Move($incoming, $current)
        } catch {
            if ([IO.Directory]::Exists($previous)) { [IO.Directory]::Move($previous, $current) }
            throw
        }
    } finally {
        $directory = Get-Item -LiteralPath $staging
        if ($directory.Parent.FullName -ne $Store -or $directory.LinkType) {
            throw "Unexpected staging directory at $staging."
        }
        if ([IO.Directory]::Exists($current) -or -not [IO.Directory]::Exists($previous)) {
            Remove-Item -LiteralPath $directory.FullName -Recurse -Force
        }
    }
}

function Add-SkillLink {
    param([string] $Directory, [string] $Name, [string] $Target, [string] $LegacyDirectory)

    $link = Join-Path $Directory $Name
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -and $existing.Target -eq $Target) { return }
        Write-Warning "Preserved existing skill at $link."
        return
    }
    if ($LegacyDirectory) {
        $legacy = Join-Path $LegacyDirectory $Name
        if (Get-Item -LiteralPath $legacy -Force -ErrorAction SilentlyContinue) {
            Write-Warning "Preserved existing Codex skill at $legacy."
            return
        }
    }
    $linkType = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $linkType -Path $link -Target $Target | Out-Null
}

$profilePath = (Get-Item -LiteralPath $TargetHome).FullName
$installRoot = Join-Path $profilePath '.agent-guidance'
[void] [IO.Directory]::CreateDirectory($installRoot)
$store = Get-Item -LiteralPath $installRoot -Force
if ($store.LinkType) { throw "Expected a regular install root at $installRoot." }
$lock = [IO.File]::Open((Join-Path $store.FullName 'install.lock'), 'OpenOrCreate', 'Write', 'None')
try {
    Publish-SkillBundle $store.FullName $sources
    $codexSkills = [IO.Directory]::CreateDirectory((Join-Path $profilePath '.agents/skills')).FullName
    $claudeSkills = [IO.Directory]::CreateDirectory((Join-Path $profilePath '.claude/skills')).FullName
    $legacyCodex = Join-Path $profilePath '.codex/skills'
    if ($env:CODEX_HOME -and $profilePath -eq (Get-Item -LiteralPath $HOME).FullName) {
        $legacyCodex = Join-Path $env:CODEX_HOME 'skills'
    }
    foreach ($source in $sources) {
        $target = Join-Path (Join-Path $store.FullName 'skills') $source.Name
        Add-SkillLink $codexSkills $source.Name $target $legacyCodex
        Add-SkillLink $claudeSkills $source.Name $target
    }
} finally {
    $lock.Dispose()
}
Write-Output ("Prepared {0} skills. Both agents can use the linked skills." -f $sources.Count)
