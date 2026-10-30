# dotfiles

Personal AI developer environment, kept in version control so it can be set up on any machine with one command. It contains:

- **Custom Claude Code skills**: reusable agent workflows such as multi-agent councils with peer review, parallel strategy runs with a judge agent, and self-verification modes that try to disprove a draft answer before shipping it
- **Perplexity Ask MCP server**: a TypeScript [Model Context Protocol](https://modelcontextprotocol.io) server that gives Claude live web search with citations
- **Cross-platform bootstrap scripts** that link everything into place on Windows, macOS and Linux

**Stack:** Claude Code · Model Context Protocol · TypeScript / Node.js · PowerShell · Bash

## Layout

```
dotfiles/
  claude/
    skills/              # each subfolder is a skill (a SKILL.md file)
  mcp-servers/
    perplexity-ask/      # MCP server: live web search for Claude via Perplexity
  bootstrap.ps1          # Windows: link skills into ~/.claude/skills
  bootstrap.sh           # macOS/Linux: symlink skills into ~/.claude/skills
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

The scripts are idempotent: links that already exist are skipped, and folders that aren't
links created by the script are never overwritten.

## Adding a new skill

Drop the skill folder into `claude/skills/`, run the bootstrap script again (it skips
folders that are already linked), then commit and push.

## Perplexity Ask MCP server

Lets Claude search the web live through Perplexity. It provides two tools:

- `perplexity_ask`: Perplexity Agent API; returns a written answer with citations
- `perplexity_search`: Search API; returns ranked results for Claude to summarise

The server was migrated from Perplexity's retired Sonar chat-completions endpoint to the Agent API.
Build and configuration steps are in [mcp-servers/perplexity-ask/README.md](mcp-servers/perplexity-ask/README.md).
