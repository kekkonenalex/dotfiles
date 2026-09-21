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
