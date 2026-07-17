#!/usr/bin/env bash
set -euo pipefail

POST_CREATE_LOG="${HOME}/.post-create.log"
warn() {
  echo "[post-create] WARNING: $*" | tee -a "$POST_CREATE_LOG" >&2
}

# setting on "strict, fail-fast" -euo pipefail
echo "Running post-create script..." > "$POST_CREATE_LOG"

# uv + project dependencies
curl -LsSf https://astral.sh/uv/install.sh | sh
. "$HOME/.local/bin/uv"
uv sync

echo "uv sync complete" >> "$POST_CREATE_LOG"
echo "Installing codegraph..." >> "$POST_CREATE_LOG"

npm install -g @colbymchenry/codegraph
codegraph install --yes || warn "codegraph install failed - MCP server not available"
codegraph init || warn "codegraph init failed - index not built" 

echo "Installing Claude plugin..." >> "$POST_CREATE_LOG"

claude plugin marketplace add DietrichGerbert/ponytail || warn "Failed to add ponytail plugin to marketplace"
claude plugin install ponytail@ponytail || warn "Failed to install ponytail plugin"
