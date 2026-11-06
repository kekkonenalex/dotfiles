# dotfiles

Personal AI developer environment, kept in version control so it can be set up on any machine with one command. It contains:

- **Custom Claude Code skills**: reusable agent workflows such as multi-agent councils with peer review, parallel strategy runs with a judge agent, and self-verification modes that try to disprove a draft answer before shipping it
- **Shared CLAUDE.md**: personal instructions Claude Code loads on every machine, which Claude keeps up to date itself with one commit per change
- **Perplexity Ask MCP server**: a TypeScript [Model Context Protocol](https://modelcontextprotocol.io) server that gives Claude live web search with citations
- **Cross-platform bootstrap scripts** that link everything into place on Windows, macOS and Linux

**Stack:** Claude Code · Model Context Protocol · TypeScript / Node.js · PowerShell · Bash

## Layout

```
dotfiles/
  claude/
    CLAUDE.md            # shared instructions, imported by ~/.claude/CLAUDE.md on every machine
    chat-preferences.md  # short version to paste into the Claude apps' chat settings
    skills/              # each subfolder is a skill (a SKILL.md file)
    plugins.txt          # Claude Code plugins (and their marketplaces) to install on every machine
  mcp-servers/
    perplexity-ask/      # MCP server: live web search for Claude via Perplexity
  bootstrap.ps1          # Windows: link skills, set up ~/.claude/CLAUDE.md, install plugins
  bootstrap.sh           # macOS/Linux: the same with symlinks
```

## Setup on a new machine

1. Clone this repo:
   ```bash
   git clone https://github.com/kekkonenalex/dotfiles ~/dotfiles
   ```
2. Run the bootstrap script for your OS:
   - Windows (PowerShell): `~/dotfiles/bootstrap.ps1`
   - macOS/Linux (bash): `~/dotfiles/bootstrap.sh`

This links every folder under `claude/skills/` into `~/.claude/skills/`, so editing a skill
in the dotfiles repo (and running `git pull`) updates it everywhere without reinstalling.

On Windows the link is a directory **junction** (`New-Item -ItemType Junction`), which doesn't
require admin rights or Developer Mode, unlike a symlink. On macOS/Linux it's a normal symlink.

The scripts also install every plugin listed in `claude/plugins.txt` through the `claude` CLI
(`claude plugin marketplace add` and `claude plugin install`, user scope). To add a plugin
everywhere, add a line there and re-run the bootstrap on each machine.

The scripts are idempotent: links that already exist are skipped, folders that aren't
links created by the script are never overwritten, and installed plugins are left as they are.

## CLAUDE.md

Each machine's `~/.claude/CLAUDE.md` starts with the line `@~/dotfiles/claude/CLAUDE.md`, which
pulls in the shared instructions; below it go private notes that apply only to that machine.
Bootstrap creates that file, or adds the import line to the top of an existing one (keeping the old
version as `CLAUDE.md.prev`). An import is used because a file symlink would need admin rights or
Developer Mode on Windows.

Claude edits the shared file itself and commits each change as `CLAUDE.md: <what changed>`, so
`git revert <hash>` undoes one. Run `git pull` on the other machines to pick changes up.
This repo is public: keep anything private in the per-machine file.

Claude Code (CLI, desktop Code tab, IDE extensions) reads these files. The regular chat in the
Claude apps doesn't; paste `claude/chat-preferences.md` into its personal preferences setting instead.

## Adding a new skill

Drop the skill folder into `claude/skills/`, run the bootstrap script again (it skips
folders that are already linked), then commit and push.

## Perplexity Ask MCP server

Lets Claude search the web live through Perplexity. It provides two tools:

- `perplexity_ask`: Perplexity Agent API; returns a written answer with citations
- `perplexity_search`: Search API; returns ranked results for Claude to summarise

The server was migrated from Perplexity's retired Sonar chat-completions endpoint to the Agent API.
Build and configuration steps are in [mcp-servers/perplexity-ask/README.md](mcp-servers/perplexity-ask/README.md).
