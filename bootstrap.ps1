# Links every folder under claude/skills into ~/.claude/skills using directory junctions.
# Junctions work without admin rights or Developer Mode on Windows.
$dotfiles = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsSrcDir = Join-Path $dotfiles "claude\skills"
$skillsDestDir = "$HOME\.claude\skills"

New-Item -ItemType Directory -Force -Path $skillsDestDir | Out-Null

Get-ChildItem -Directory $skillsSrcDir | ForEach-Object {
    $target = $_.FullName
    $link = Join-Path $skillsDestDir $_.Name

    if (Test-Path $link) {
        $item = Get-Item $link
        if ($item.LinkType -eq "Junction" -and $item.Target -eq $target) {
            Write-Output "OK (already linked): $($_.Name)"
            return
        }
        Write-Output "SKIP (exists, not our junction): $($_.Name) -- remove it manually if you want to relink"
        return
    }

    New-Item -ItemType Junction -Path $link -Target $target | Out-Null
    Write-Output "linked $($_.Name)"
}

# Make ~/.claude/CLAUDE.md import the shared claude/CLAUDE.md. File symlinks need admin or
# Developer Mode on Windows, so the device file holds a one-line @import instead.
$importLine = "@~/dotfiles/claude/CLAUDE.md"
$deviceFile = "$HOME\.claude\CLAUDE.md"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

if (-not (Test-Path $deviceFile)) {
    $stub = "$importLine`n`n# This device (private, not synced)`n`n- Describe this device here: personal or work laptop, OS, anything Claude should know only on this machine.`n"
    [System.IO.File]::WriteAllText($deviceFile, $stub, $utf8NoBom)
    Write-Output "created $deviceFile (importing the shared CLAUDE.md)"
} elseif ((Get-Content $deviceFile -Raw) -match [regex]::Escape($importLine)) {
    Write-Output "OK (already imports the shared CLAUDE.md): $deviceFile"
} else {
    Copy-Item $deviceFile "$deviceFile.prev" -Force
    $existing = [System.IO.File]::ReadAllText($deviceFile)
    [System.IO.File]::WriteAllText($deviceFile, "$importLine`n`n$existing", $utf8NoBom)
    Write-Output "added the import to the top of $deviceFile (old version saved as CLAUDE.md.prev)"
}

# Install the Claude Code plugins listed in claude/plugins.txt. Both commands are no-ops when
# the marketplace or plugin is already there, so re-running the bootstrap is safe.
$pluginList = Join-Path $dotfiles "claude\plugins.txt"
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Output "SKIP plugins: the claude CLI isn't on PATH. Install Claude Code, then re-run this script."
} else {
    Get-Content $pluginList | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $parts = $line -split "\s+"
        $plugin = $parts[0]
        if ($parts.Count -gt 1) {
            claude plugin marketplace add $parts[1] | Out-Null
            if ($LASTEXITCODE -ne 0) { Write-Output "FAILED to add marketplace $($parts[1])"; return }
        }
        claude plugin install $plugin | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Output "plugin ready: $plugin" } else { Write-Output "FAILED to install plugin $plugin" }
    }
}
