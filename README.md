# Oxagen — Cursor plugin

> Ontology layer for AI agents. Typed, queryable knowledge graph exposed
> to Cursor as MCP-native tools so every answer, edit, triage, or recall
> is grounded in deterministic graph context instead of guessing.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Plugin: Cursor](https://img.shields.io/badge/Cursor-plugin-7c3aed)](https://cursor.com/docs)
[![Docs](https://img.shields.io/badge/docs-docs.oxagen.ai-blue)](https://docs.oxagen.ai/plugins/cursor)

- **Docs:** <https://docs.oxagen.ai/plugins/cursor>
- **App:** <https://app.oxagen.ai>
- **Issues:** <https://github.com/oxagenai/cursor-plugin/issues>

---

## TL;DR

Install once. Get:

- A typed, deterministic **knowledge graph** of your workspace (code, history, tests, CI, security alerts, incidents, ownership, runbooks, customers — whatever the workspace ontology tracks).
- **Always-on memory** — every meaningful action is captured, recurring patterns are detected, past failures are injected as warnings before similar work, and procedures get promoted to reusable recipes.
- **Four routing rules** under `.cursor/rules/` covering the gate policy, the full MCP tool catalog, write-back conventions, and a cookbook that maps the Claude Code `/oxagen:*` slash-command surface to Cursor phrasings.
- A **sessionStart hook** that pins three guarantees on every turn: *graph first*, *memory always recalled*, *coordination respected*.

---

## Install

### One-shot installer (recommended)

From the repo you want to wire to Oxagen:

```bash
git clone https://github.com/oxagenai/cursor-plugin /tmp/oxagen-cursor
/tmp/oxagen-cursor/scripts/install.sh
```

The script copies the `.cursor/` tree (rules, `mcp.json`, `hooks.json`,
`hooks/session-start`) into the current project. Reload Cursor and the
`oxagen` MCP server appears under **Settings → MCP**.

### Manual install

Copy the `.cursor/` directory from this plugin into your project root:

```bash
cp -r plugins/oxagen-cursor/.cursor /path/to/your-repo/
chmod +x /path/to/your-repo/.cursor/hooks/session-start
```

### Wire your workspace

1. Mint a workspace token at <https://app.oxagen.ai/setup/cursor>.
2. Export it so Cursor inherits it on launch:

   ```bash
   export OXAGEN_MCP_TOKEN=oxa_live_…
   ```

   Add the export to your shell profile (`~/.zshrc`, `~/.bashrc`).
3. Reload Cursor (`Cmd+Shift+P` → "Reload Window").
4. Verify: **Settings → MCP** lists `oxagen` with its full tool set.

---

## What the plugin guarantees

When the Oxagen plugin is enabled, **on every session** the `sessionStart`
hook injects an `<EXTREMELY_IMPORTANT>` preamble that tells the agent:

1. **Graph first, guess second.** Before any non-trivial action — code edit, research synthesis, incident triage, ops change, customer-impact analysis, policy lookup — query the Oxagen graph (`ontology.*`, `code.*`, `incident.*`, `security.*`).
2. **Memory always recalled.** At the start of any task, call `memory.recall` (or `memory.context_inject`) on the intent. If a procedure or episode matches, prefer it over rediscovery. After meaningful work, persist what you learned.
3. **Coordinate.** Use `agent.list_active_claims` and `agent.claim_work` when other sessions may be touching the same scope.

The full routing policy lives in the `using-oxagen` rule (`alwaysApply: true`). The complete tool catalog lives in `oxagen-tool-reference`; write-back conventions live in `oxagen-dogfooding`. Both are description-driven (agent-requested) so they load only when relevant.

---

## Real-world use cases — beyond agentic coding

The plugin's value is the typed graph + memory layer. Coding is the most
obvious surface. It is not the only one. Anything Oxagen ingests becomes
queryable and groundable.

### Engineering

- **Refactor with confidence.** Ask "blast radius of `process_payment`" and the agent calls `ontology.impact_of` — returns callers, dependents, PageRank, and reach paths *before* you ship a signature change.
- **Onboarding.** "summarise this repo" → `code.repo_overview`; "who owns the billing module?" → `code.who_knows_about`. New hire gets a cartography of the system and its owners in five minutes.
- **Dead-code audit.** "list nodes with zero callers and no EXPORTS edge" → `ontology.ask` returns provably dead symbols. Safe to delete.

### Incident response & SRE

- **Blast-radius from a stack trace.** Find the symbol, run impact, pull PR history — minutes after the page fires.
- **Runbook recall.** "do we have a procedure for redis OOM during ingest?" → `memory.procedure_for` pulls back the procedure stored from the last incident; no wiki hunting at 3am.

### Security & compliance

- **Triage with reach.** "open security alerts" → `security.open_alerts` returns Dependabot / CodeQL / secret-scan findings joined to the call graph. "alert N context" → affected nodes + recommendation + advisory link.
- **Supply-chain audit.** "dependencies introduced in the last 30 days with no PR review" — typed query, deterministic answer.

### Multi-agent fleets

- **Claim before edit.** Ask the agent to "claim `services/api/.../service.py:50-120`" → `agent.claim_work` registers the lock; other Oxagen-connected sessions see it and back off.
- **Share findings.** `agent.record_finding` persists a typed observation ("this caller breaks if signature changes") on the affected node; `agent.get_findings` retrieves them at the start of the next task.

---

## Command surface

Cursor has no slash-command primitive equivalent to Claude Code's `/oxagen:*`. The Oxagen MCP server exposes the same tool surface; the `oxagen-commands.mdc` rule is the routing table that maps user phrasings to MCP calls.

Examples — say any of these in chat and the agent routes via the cookbook:

| You say | Agent calls |
|---|---|
| "blast radius of `process_payment`" | `ontology.impact_of` |
| "who calls `parse_request`?" | `code.find_callers` |
| "what changed in the last week?" | `code.recent_changes` |
| "find tests for `OrderService`" | `code.tests_for` |
| "what's failing on main?" | `code.failing_tests` |
| "open security alerts" | `security.open_alerts` |
| "do we have a procedure for X?" | `memory.procedure_for` |
| "claim `services/api/foo.py:42-90`" | `agent.claim_work` |

The full routing table — discovery, traversal, history, ownership, tests, CI, security, memory, coordination — lives in [`.cursor/rules/oxagen-commands.mdc`](./.cursor/rules/oxagen-commands.mdc).

---

## MCP tool surface

All tools follow `mcp__oxagen__<group>_<action>` and return the canonical
SPEC §7.9 envelope: `results`, `evidence`, `tokens_used_estimate`,
`counterfactual_estimate_tokens`, `counterfactual_method`, `cursor`,
`tenant_scoped_at`.

| Group | Surface |
|---|---|
| `ontology.*` | `ask`, `get_node`, `list_nodes`, `create_node`, `list_edges`, `create_edge`, `list_types`, `pagerank`, `communities`, `traverse`, `explain_function`, `impact_of`, `symbol_context`, `refresh_repo`, merge-queue tools |
| `code.*` (discovery) | `repo_overview`, `module_tree`, `find_symbol`, `describe_symbol`, `read_symbol`, `find_pattern` |
| `code.*` (traversal) | `find_callers`, `callees_of`, `find_dependencies`, `find_path`, `get_neighborhood`, `references_to`, `co_changes_with`, `find_cycles`, `find_dead_code`, `stats` |
| `code.*` (history) | `recent_changes`, `blame_enriched`, `pr_context`, `pr_history`, `who_knows_about`, `expertise`, `issue_context`, `find_issues`, `discussion_context` |
| `code.*` (tests + CI) | `tests_for`, `coverage_for`, `failing_tests`, `flaky_tests`, `last_run`, `run_failures` |
| `code.*` (deps) | `dependencies`, `dependency_graph` |
| `agent.*` | `start_session`, `heartbeat`, `end_session`, `claim_work`, `release_claim`, `record_finding`, `get_findings`, `list_active_claims` |
| `memory.*` | `recall`, `remember`, `procedure_for`, `forget`, `search`, `context`, `annotate`, `metric_*`, `benchmark_*`, `context_inject` |
| `security.*` | `open_alerts`, `alert_context` |
| `workspace.*` | `list`, `bind`, `enable_memory`, `disable_memory` |
| `incident.*` | `open`, `resolve`, `link` |

Per-tool descriptions live at <https://docs.oxagen.ai/plugins/cursor#mcp-tool-reference> and in [`./.cursor/rules/oxagen-tool-reference.mdc`](./.cursor/rules/oxagen-tool-reference.mdc).

---

## How it's wired

```
plugins/oxagen-cursor/
├── plugin.json                # Plugin metadata (name, version, primitives)
├── .cursor/
│   ├── mcp.json               # Streamable-HTTP MCP server — points at mcp.oxagen.ai
│   ├── hooks.json             # sessionStart hook registration
│   ├── hooks/
│   │   └── session-start      # Injects the <EXTREMELY_IMPORTANT> preamble
│   └── rules/
│       ├── using-oxagen.mdc           # alwaysApply: true — gate policy
│       ├── oxagen-tool-reference.mdc  # agent-requested — full tool catalog
│       ├── oxagen-dogfooding.mdc      # agent-requested — write-back conventions
│       └── oxagen-commands.mdc        # agent-requested — slash-command cookbook
├── scripts/
│   └── install.sh             # Copies .cursor/ into a target project
├── design/
│   └── cursor-plugin-design.md
├── README.md                  # This file
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE                    # MIT
```

### Environment

| Variable | Required | Purpose |
|----------|----------|---------|
| `OXAGEN_MCP_TOKEN` | Yes | Bearer token for `mcp.oxagen.ai`. Mint at `app.oxagen.ai/setup/cursor` and export in your shell so Cursor inherits it. |

---

## Troubleshooting

**No tools listed after setup.** Check that `OXAGEN_MCP_TOKEN` is exported in the shell that launched Cursor. `echo $OXAGEN_MCP_TOKEN` to verify, then quit and relaunch Cursor from that shell.

**`memory.*` tools not returning results.** Memory tools are always registered; capture only activates after the workspace owner enables memory in the app.

**401 on every call.** Token expired or revoked. Generate a new token at **Settings → MCP → Tokens** in the app, update the shell export, relaunch Cursor.

**Ingest stuck / graph empty.** Check **Settings → Connections** in the app. Reconnect GitHub if errored, then trigger a manual re-ingest. Or ask the agent to call `ontology.refresh_repo`.

**Stale claim blocking another session.** Ask the agent for "active claims" and then "force-claim `<scope>`" to override (records an audit event).

---

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md). PRs welcome — especially additional command-cookbook entries, new use-case examples, and adapters that bridge Cursor + Claude Code + Windsurf rule trees.

---

## License

[MIT](./LICENSE) · © 2026 Oxagen, Inc.
