# Contributing — Oxagen Cursor plugin

This tree is the canonical source for the Oxagen Cursor plugin. The
public marketplace mirror at `oxagenai/cursor-plugin` is release-stamped
from this directory.

## Local development

1. Clone `oxagen-platform` and open it in Cursor.
2. From a project where you want to test the plugin, run:

   ```bash
   /path/to/oxagen-platform/plugins/oxagen-cursor/scripts/install.sh
   ```

3. Export `OXAGEN_MCP_TOKEN` (mint one at `app.oxagen.ai/setup/cursor`).
4. Reload Cursor (`Cmd+Shift+P` → "Reload Window") and confirm the
   `oxagen` MCP server is listed under **Settings → MCP**.

## What lives where

| Path | Purpose |
|---|---|
| `.cursor/mcp.json` | Streamable-HTTP MCP server config |
| `.cursor/hooks.json` | Lifecycle hook registration |
| `.cursor/hooks/session-start` | Always-on preamble injection |
| `.cursor/rules/using-oxagen.mdc` | Always-applied routing policy |
| `.cursor/rules/oxagen-tool-reference.mdc` | Agent-requested tool catalog |
| `.cursor/rules/oxagen-dogfooding.mdc` | Agent-requested write-back conventions |
| `.cursor/rules/oxagen-commands.mdc` | Agent-requested slash-command cookbook |
| `plugin.json` | Plugin metadata (name, version, primitives) |
| `scripts/install.sh` | Copy `.cursor/` into a target project |
| `design/` | Non-executable design docs (not auto-discovered) |

## Rule authoring conventions

- Front-matter: `.mdc` files use YAML with `alwaysApply`, `description`, and `globs`. Only `using-oxagen.mdc` sets `alwaysApply: true`. Every other rule is description-driven (agent-requested).
- Body: declarative present tense; declarative headings; tables for routing tables. No marketing voice, no emoji, no exclamation marks.
- Tool names: quote the MCP tool name verbatim — `code.find_callers`, `memory.recall`, `ontology.symbol_context`. Never paraphrase.

## Submitting changes

1. Branch from `main`: `feat/OXA-NNN/<slug>` (lowercase kebab-case).
2. Open a draft PR with summary + test plan + Linear link.
3. PR auto-flips to ready when CI is green and every review thread is answered.

## License

[MIT](./LICENSE) — same as the Oxagen Claude Code plugin.
