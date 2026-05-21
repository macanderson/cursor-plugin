#!/usr/bin/env bash
# Install the Oxagen Cursor plugin into a target project.
#
# Copies the `.cursor/` tree from this plugin into the target project's
# root, preserving any existing rules / hooks the user has authored.
# Run from the plugin root or pass an absolute target path.
#
# Usage:
#   ./scripts/install.sh                 # installs into $PWD
#   ./scripts/install.sh /path/to/repo   # installs into the given repo

set -euo pipefail

info() { printf '\033[1;36m%s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m%s\033[0m\n' "$*" >&2; }
fail() { printf '\033[1;31m%s\033[0m\n' "$*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC="${PLUGIN_ROOT}/.cursor"
TARGET="${1:-$PWD}"

[ -d "$SRC" ] || fail "plugin .cursor/ not found at $SRC"
[ -d "$TARGET" ] || fail "target directory does not exist: $TARGET"

info "Installing Oxagen Cursor plugin into: $TARGET"

mkdir -p "$TARGET/.cursor/rules" "$TARGET/.cursor/hooks"

# Back up mcp.json and hooks.json if they already exist with content,
# so existing user config (e.g. other MCP servers) is never silently lost.
# Timestamp the backup so re-running the installer never overwrites a prior backup.
for json_file in mcp.json hooks.json; do
    dest="$TARGET/.cursor/${json_file}"
    if [ -s "$dest" ]; then
        ts="$(date +%Y%m%d_%H%M%S)"
        backup="${dest}.bak.${ts}"
        cp "$dest" "$backup"
        warn "Backed up existing ${json_file} → ${json_file}.bak.${ts} (your entries are preserved there)"
    fi
done

cp -f "$SRC/mcp.json"   "$TARGET/.cursor/mcp.json"
cp -f "$SRC/hooks.json" "$TARGET/.cursor/hooks.json"

for f in "$SRC"/rules/*.mdc; do
    cp -f "$f" "$TARGET/.cursor/rules/"
done

for f in "$SRC"/hooks/*; do
    cp -f "$f" "$TARGET/.cursor/hooks/"
done

chmod +x "$TARGET/.cursor/hooks/session-start" 2>/dev/null || true

ok "Files installed."

if [ -z "${OXAGEN_MCP_TOKEN:-}" ]; then
    warn "OXAGEN_MCP_TOKEN is not set in your shell."
    warn "Visit https://app.oxagen.ai/setup/cursor to mint a token, then:"
    warn "  export OXAGEN_MCP_TOKEN=oxa_live_…"
    warn "Add the export to your shell profile so Cursor inherits it."
fi

ok "Done. Reload Cursor (Cmd+Shift+P → 'Reload Window') to pick up the MCP server."
