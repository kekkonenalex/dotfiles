# dotfiles

Personal config tracked across machines. Currently: Claude Code skills.

## Layout

```
dotfiles/
  claude/
    skills/           # each subfolder is a skill (a SKILL.md file)
  bootstrap.ps1        # Windows: link skills into ~/.claude/skills
  bootstrap.sh          # macOS/Linux: symlink skills into ~/.claude/skills
```

## Setup on a new machine

1. Clone this repo:
   ```bash
   git clone <your-remote-url> ~/dotfiles
   ```
2. Run the bootstrap script for your OS:
   - Windows (PowerShell): `~/dotfiles/bootstrap.ps1`
   - macOS/Linux (bash): `~/dotfiles/bootstrap.sh`

This links every folder under `claude/skills/` into `~/.claude/skills/`, so editing a skill
in the dotfiles repo (and running `git pull`) updates it everywhere without reinstalling.

On Windows the link is a directory **junction** (`New-Item -ItemType Junction`), which doesn't
require admin rights or Developer Mode, unlike a symlink. On macOS/Linux it's a normal symlink.

## Adding a new skill

Drop the skill folder into `claude/skills/`, run the bootstrap script again (it skips
folders that are already linked), then commit and push.
