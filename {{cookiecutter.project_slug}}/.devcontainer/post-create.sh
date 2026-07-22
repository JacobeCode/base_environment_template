#!/usr/bin/env bash
set -euo pipefail

# shared logging sourcing - writes to logs/post-create.log (last run save)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/_logging.sh" post-create

# setting on "strict, fail-fast" -euo pipefail
echo "Running post-create script..." > "$POST_CREATE_LOG"

# uv + project dependencies
curl -LsSf https://astral.sh/uv/install.sh | sh
. "$HOME/.local/bin/uv"
uv sync

echo "uv sync complete" >> "$POST_CREATE_LOG"

# jq install for ask.sh to parse JSON
if ! command -v jq >/dev/null; then
  log "Installing jq"
  sudo apt-get update -qq && sudo apt-get install -y -qq jq || warn "jq install failed — ask.sh will not work"
fi

# ---------- AGENT CODING TOOLS ----------  

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

# defaulting to uv managment as project is based on uv
uv tool install headroom-cli || warn "Failed to install headroom-cli"
headroom mcp install || warn "Failed to install headroom MCP plugin"

# ---------- GPU TRAINING TOOLS ----------
{%- if cookiecutter.gpu_training == "yes" %}
uv sync --group train
echo "==> Verifying CUDA availability in the dev container:"

uv run python - <<'PY' || warn "Failed to run python to check CUDA availability or no CUDA device visible — check NVIDIA Container Toolkit on the host and the compose GPU reservatio"

import torch

print("torch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("CUDA device name:", torch.cuda.get_device_name(torch.cuda.current_device()))
else:
    print("WARNING: no CUDA device seen. Check NVIDIA Container Toolkit on the host "
          "and that gpu_training=yes wired the GPU reservation into docker-compose.yml.")
PY
{%- endif %}

# ---------- GIT HOOKS ----------

# .git/hooks/ not tracked, so run per clone to install pre-commit hooks if .pre-commit-config.yaml is present
if [ -d .git ] && [ -f .pre-commit-config.yaml ]; then
  uv run pre-commit install --install-hooks || warn "Failed to install pre-commit hooks"
else
  warn "No .git directory or .pre-commit-config.yaml found, skipping pre-commit hook installation"
fi

# --------- LOG REPORTING ----------

echo "Post-create script completed. Log written to $POST_CREATE_LOG"
if [ "$WARN_COUNT" -gt 0 ]; then
  err "post-create finished with $WARN_COUNT warning(s) — see $LOG_FILE"
  grep '\[WARN\]' "$LOG_FILE" || true
else
  log "No warnings/errors during post-create. Post-create completed."
fi
