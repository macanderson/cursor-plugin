# Changelog

All notable changes to the Oxagen Cursor plugin are documented here.
This project follows [Semantic Versioning](https://semver.org/).

## [0.21.8] — 2026-05-20

### Added
- Initial release. Ports the Oxagen Claude Code plugin (`oxagen-claude-code` v0.21.8) to Cursor's plugin primitives:
  - `.cursor/mcp.json` — Streamable-HTTP transport to `mcp.oxagen.ai/mcp/` with `${env:OXAGEN_MCP_TOKEN}` interpolation.
  - `.cursor/hooks.json` + `.cursor/hooks/session-start` — `sessionStart` hook injects the `using-oxagen` gate as `additional_context` so the graph-first / memory-first / coordinate-first preamble lands on every Cursor session.
  - `.cursor/rules/using-oxagen.mdc` — `alwaysApply: true` mirror of the gate skill.
  - `.cursor/rules/oxagen-tool-reference.mdc` — agent-requested catalog of the full MCP tool surface.
  - `.cursor/rules/oxagen-dogfooding.mdc` — agent-requested write-back conventions.
  - `.cursor/rules/oxagen-commands.mdc` — agent-requested cookbook mapping the 50+ Claude Code slash commands to Cursor phrasing and MCP tool calls.
- `scripts/install.sh` — one-shot copy of the `.cursor/` tree into a target project.
- `plugin.json` metadata + `LICENSE` (MIT) + `README.md` + `CONTRIBUTING.md`.
