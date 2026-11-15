#Requires -Version 7.4
# Exercises both agent destinations and upgrades from the retired review skills.
$ErrorActionPreference = 'Stop'
$installer = Join-Path $PSScriptRoot 'install.ps1'
$profilePath = [IO.Directory]::CreateTempSubdirectory('guidance install test-').FullName
$codex = Join-Path $profilePath '.agents/skills'
$claude = Join-Path $profilePath '.claude/skills'
$bundle = Join-Path $profilePath '.agent-guidance/skills'

try {
    & $installer -TargetHome $profilePath
    $kind = if ($IsWindows) { 'Junction' } else { 'SymbolicLink' }
    foreach ($directory in @($codex, $claude)) {
        $entry = Get-Item -LiteralPath (Join-Path $directory 'agent-delegate')
        if ($entry.LinkType -ne $kind -or $entry.LinkTarget -ne (Join-Path $bundle 'agent-delegate')) {
            throw "The skill does not link to the shared bundle: $($entry.FullName)"
        }
        foreach ($skill in @('agent-delegate', 'quality-review', 'learn', 'ui-ux-pro-max', 'unity-guideline')) {
            if (-not (Test-Path -LiteralPath (Join-Path $directory "$skill/SKILL.md") -PathType Leaf)) {
                throw "Missing $skill in $directory"
            }
        }
        $oldBundle = [IO.Directory]::CreateDirectory((Join-Path $bundle 'codex-check')).FullName
        New-Item -ItemType $kind -Path (Join-Path $directory 'codex-check') -Target $oldBundle | Out-Null
    }
    $personal = [IO.Directory]::CreateDirectory((Join-Path $claude 'claude-check')).FullName
    $marker = Join-Path $personal 'SKILL.md'
    [IO.File]::WriteAllText($marker, 'A manually installed skill.')

    & $installer -TargetHome $profilePath
    foreach ($directory in @($codex, $claude)) {
        if (Get-Item -LiteralPath (Join-Path $directory 'codex-check') -Force -ErrorAction SilentlyContinue) {
            throw "A retired link survived reinstall in $directory"
        }
        if (-not (Test-Path -LiteralPath (Join-Path $directory 'agent-delegate/SKILL.md') -PathType Leaf)) {
            throw "The new skill disappeared during reinstall in $directory"
        }
    }
    if ([IO.File]::ReadAllText($marker) -cne 'A manually installed skill.') {
        throw 'Reinstall changed a manually installed skill.'
    }
    Write-Output "Installer smoke test passed using $kind links."
} finally {
    $directory = Get-Item -LiteralPath $profilePath
    $tempRoot = Get-Item -LiteralPath ([IO.Path]::GetTempPath())
    if ($directory.Parent.FullName -ne [IO.Path]::TrimEndingDirectorySeparator($tempRoot.FullName) -or $directory.LinkType) {
        throw "Unexpected test profile at $profilePath."
    }
    Remove-Item -LiteralPath $directory.FullName -Recurse -Force
}
