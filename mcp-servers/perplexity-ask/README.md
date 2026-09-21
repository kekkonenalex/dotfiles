# Perplexity Ask MCP Server

MCP server that lets Claude search the web live via Perplexity's Sonar API.
Source: https://github.com/thangchung/ppl-ai-modelcontextprotocol (fork of
https://github.com/perplexityai/modelcontextprotocol). Kept here so it can be
pulled onto any machine via this dotfiles repo. Full upstream instructions in
[UPSTREAM_README.md](./UPSTREAM_README.md).

## Setup on a new device

```bash
cd mcp-servers/perplexity-ask
npm install
npm run build
```

Get a Sonar API key from https://www.perplexity.ai/settings/api, then add
this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "perplexity-ask": {
      "command": "node",
      "args": ["/absolute/path/to/dotfiles/mcp-servers/perplexity-ask/dist/index.js"],
      "env": {
        "PERPLEXITY_API_KEY": "YOUR_API_KEY_HERE"
      }
    }
  }
}
```

Replace the path with where you cloned this dotfiles repo on that machine,
and the key with your own. Restart Claude Desktop afterward.
