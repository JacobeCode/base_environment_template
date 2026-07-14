#!/usr/bin/env bash
set -euo pipefail

# building log with non-fatal warnings and errors to leave a trace of what happened during post-create (broken tools, missing dependencies, etc.)
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

# --- AGENT CODING TOOLS ---  

# CodeGraph — local code knowledge graph, exposed to Claude Code over MCP.
echo "Installing codegraph..." >> "$POST_CREATE_LOG"

npm install -g @colbymchenry/codegraph
codegraph install --yes || warn "codegraph install failed - MCP server not available"
codegraph init || warn "codegraph init failed - index not built" 

# Ponytail (Claude Code plugin marketplace) — "write the least code" skill.
# Install automation v.s. UI install
echo "Installing Claude plugin..." >> "$POST_CREATE_LOG"

claude plugin marketplace add DietrichGerbert/ponytail || warn "Failed to add ponytail plugin to marketplace"
claude plugin install ponytail@ponytail || warn "Failed to install ponytail plugin"

# 3. Headroom (pip) — input-token compression MCP (open-source CLI, Apache 2.0).
# For Max - relives cap rates
echo "Installing Headroom..." >> "$POST_CREATE_LOG"

pip install --user --break-system-packages headroom-cli || warn "Failed to install headroom-cli"
headroom mcp install || warn "Failed to install headroom MCP plugin"
