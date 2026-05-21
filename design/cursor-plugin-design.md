# Design — Oxagen Cursor plugin

> Internal design doc. Not auto-discovered by Cursor; kept in-tree as the
> ejectable design record. After this design ships, the staff-wiki page
> at `services/internal/content/docs/plugins/cursor.mdx` is the
> system-of-record; this file remains for the ejectable mirror.

## Problem

Oxagen's Claude Code plugin ships the ontology layer into Anthropic's CLI
agent. Cursor is the largest IDE-shaped agent surface with native MCP
support. Until this plugin shipped, Cursor users had two options:

1. Copy-paste rules from the Claude Code plugin (lossy — Cursor `.mdc`
   front-matter differs from Claude Code skill front-matter).
2. Skip the routing layer entirely and let Cursor's agent ad-hoc the MCP
   tool calls — same tools, no graph-first / memory-first discipline.

Neither path delivered the same guarantees the Claude Code plugin
provides. We needed a Cursor-native tree.

## Decision

Ship a parallel tree at `plugins/oxagen-cursor/` that maps each Claude
Code primitive to its Cursor equivalent:

| Claude Code | Cursor |
|---|---|
| `.claude-plugin/plugin.json` (manifest) | `plugin.json` (metadata only — Cursor has no manifest schema) |
| `.claude-plugin/marketplace.json` | (Cursor has no marketplace schema) |
| `.mcp.json` (stdio/http) | `.cursor/mcp.json` (stdio/http/sse) |
| `hooks/hooks.json` + `hooks/session-start` | `.cursor/hooks.json` + `.cursor/hooks/session-start` |
| `skills/using-oxagen/SKILL.md` (always loaded) | `.cursor/rules/using-oxagen.mdc` (`alwaysApply: true`) |
| `skills/oxagen-tool-reference/SKILL.md` (on-demand) | `.cursor/rules/oxagen-tool-reference.mdc` (description-driven) |
| `skills/dogfooding/SKILL.md` (on-demand) | `.cursor/rules/oxagen-dogfooding.mdc` (description-driven) |
| 50+ `commands/*.md` slash commands | `.cursor/rules/oxagen-commands.mdc` (description-driven cookbook) |

### Why one cookbook rule, not 50 individual rule files

Cursor has no slash-command primitive. The agent picks rules by matching
the user's prompt against rule `description` fields. Forty-something
single-purpose rules would all try to compete for relevance; their
descriptions overlap (they're all "Oxagen commands"). One cookbook rule
with a comprehensive description and a routing table inside lets the
agent load one document and have the full surface available.

This also matches how the Claude Code commands work in practice — the
agent reads the runbook from the slash-command file and follows it. The
Cursor cookbook collapses that into one rule body.

### Why the hook runs the gate rule from `additional_context`, not just `alwaysApply: true`

`alwaysApply: true` does what it says — Cursor inlines the rule body
into context. So strictly the gate rule alone would deliver the routing
policy. But Claude Code's plugin uses a SessionStart hook with an
`<EXTREMELY_IMPORTANT>` preamble for two reasons that carry over to
Cursor:

1. **Belt-and-suspenders.** Rules can be silently disabled by a user
   (Cursor offers per-rule toggles in the UI). A hook is a separate
   delivery channel — if the rule is off, the preamble still fires.
2. **Tightened prose.** The hook preamble is a three-bullet imperative;
   the gate rule is a full routing table. The agent benefits from
   reading the imperative first.

### Cursor primitive notes (caught during research)

- Cursor sets `CURSOR_PROJECT_DIR`, not `CURSOR_PLUGIN_ROOT`. The
  pre-existing Claude Code `session-start` script has a
  `CURSOR_PLUGIN_ROOT` branch that is never hit; we did not regress on
  the Claude Code script, but the Cursor copy is keyed to the actual
  Cursor environment.
- `.cursor/hooks.json` uses `sessionStart` (camelCase), not
  `SessionStart` (PascalCase like Claude Code).
- Cursor's hook output schema for context injection is top-level
  `additional_context` (snake_case). Claude Code expects
  `hookSpecificOutput.additionalContext` (camelCase, nested).
- Cursor's `.mcp.json` accepts `${env:NAME}` interpolation in `headers`,
  `url`, `command`, `args`, `env`. Claude Code accepts `${NAME}` (no
  `env:` prefix). The bearer header in Cursor is
  `"Bearer ${env:OXAGEN_MCP_TOKEN}"`.

## Distribution

- Canonical tree: `oxagen-platform/plugins/oxagen-cursor/`.
- Public mirror (planned): `oxagenai/cursor-plugin`. Eject script
  (planned, separate Linear issue): mirrors the
  `scripts/eject-claude-code-plugin.sh` pattern — copies a clean tree,
  initializes git, prints push commands.
- Install UX: clone the mirror, run `scripts/install.sh`, export
  `OXAGEN_MCP_TOKEN`, relaunch Cursor. No marketplace integration yet —
  Cursor's marketplace doesn't accept third-party rule/MCP bundles
  directly; users install by cloning.

## Rejected alternatives

| Option | Why rejected |
|---|---|
| One-file `.cursorrules` (legacy) | Cursor 0.43+ deprecates `.cursorrules` in favor of `.cursor/rules/*.mdc`. Front-matter doesn't carry. |
| 50 individual command rules | Description overlap drowns the agent's rule-selection signal. One cookbook is denser and easier to maintain. |
| Cursor extension (VSIX) | Heavy. Cursor's rule+MCP+hook primitive set is sufficient. An extension would add a Node toolchain dependency for no behavioural gain. |
| Skip the hook, rely only on `alwaysApply: true` | See "Why the hook" above — user can toggle rules off; hook is a separate delivery channel. |
| Build a CLI wrapper (`oxagen cursor install`) | KISS gate. `scripts/install.sh` is one shell script with no dependencies; a CLI adds packaging surface for the same outcome. |

## Open questions

- Cursor's roadmap mentions a marketplace surface for one-click MCP
  install (`cursor://install-mcp` was hinted but not yet documented).
  When that lands, add a deep-link to the app's setup wizard.
- Once Cursor adds a stable slash-command primitive, split the cookbook
  back out into per-command rules to match the Claude Code surface 1:1.
- Eject script — separate Linear issue once we want the public mirror.
