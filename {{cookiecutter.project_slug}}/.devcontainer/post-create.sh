#!/usr/bin/env bash
set -euo pipefail

# shared logging sourcing - writes to logs/post-create.log (last run save)
# shellcheck source=../scripts/logging.sh
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/logging.sh" post-create

# setting on "strict, fail-fast" -euo pipefail
log "Running post-create script..."

# ---------- UV ----------

log "Installing uv and syncing project dependencies..."

# uv + project dependencies
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
uv sync

log "uv sync complete"

# ---------- JQ ----------

# jq install for ask.sh to parse JSON
if ! command -v jq >/dev/null; then
  log "Installing jq"
  (sudo apt-get update -qq && sudo apt-get install -y -qq jq) || warn "jq install failed — ask.sh will not work"
fi


# ---------- JUST ----------

if ! command -v just >/dev/null; then
  log "Installing just"
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to "$HOME/.local/bin" \
        || warn "just install failed — use the scripts/*.sh files directly instead of just <recipe>"
fi


# ---------- AGENT CODING TOOLS ----------

# CodeGraph — local code knowledge graph, exposed to Claude Code over MCP.
log "Installing codegraph..."

npm install -g @colbymchenry/codegraph
codegraph install --target=claude --yes || warn "codegraph install failed - MCP server not available"
codegraph init || warn "codegraph init failed - index not built"

# Ponytail (Claude Code plugin marketplace) — "write the least code" skill.
# Install automation v.s. UI install
log "Installing Claude plugin..."

claude plugin marketplace add DietrichGebert/ponytail || warn "Failed to add ponytail plugin to marketplace"
claude plugin install ponytail@ponytail || warn "Failed to install ponytail plugin"

# 3. Headroom (pip) — input-token compression MCP (open-source CLI, Apache 2.0).
# For Max - relives cap rates
log "Installing Headroom..."

# defaulting to uv managment as project is based on uv
uv tool install "headroom-ai[mcp]" || warn "Failed to install headroom-ai"
headroom mcp install || warn "Failed to install headroom MCP plugin"

# ---------- CONTINUE CLI ----------

# CLI Continue for local model for capabilities similar to e.g. Claude
{%- if cookiecutter.local_model != "none" %}
npm install -g @continuedev/cli || warn "Continue CLI install failed"

# symlinking .continue/config.yaml into $HOME for Continue extension to use this project's config
mkdir -p "$HOME/.continue"
ln -sf "$(pwd)/.continue/config.yaml" "$HOME/.continue/config.yaml" \
    || warn "could not symlink .continue/config.yaml into \$HOME — Continue extension will use its own default config instead of this project's"

{%- endif %}

# ---------- PRE-COMMIT TOOLS ----------

if [ -d .git ] && [ -f .pre-commit-config.yaml ]; then
    uv run pre-commit install --install-hooks || warn "pre-commit install failed"
else
    echo "[post-create] skipping pre-commit install (no .git repo or no config yet)"
fi

# ---------- GPU TRAINING TOOLS ----------
{%- if cookiecutter.gpu_usage == "yes" %}
uv sync --group train
log "==> Verifying CUDA availability in the dev container:"

uv run python - <<'PY' || warn "Failed to run python to check CUDA availability or no CUDA device visible — check NVIDIA Container Toolkit on the host and the compose GPU reservation"

import sys

import torch

print("torch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("CUDA device name:", torch.cuda.get_device_name(torch.cuda.current_device()))
else:
    print("WARNING: no CUDA device seen. Check NVIDIA Container Toolkit on the host "
    "and that gpu_usage=yes wired the GPU reservation into docker-compose.yml.")
    sys.exit(1)
PY
{%- endif %}

# --------- LOG REPORTING ----------

log "Post-create script completed. Log written to $LOG_FILE"
if [ "$WARN_COUNT" -gt 0 ]; then
  err "post-create finished with $WARN_COUNT warning(s) — see $LOG_FILE"
  grep '\[WARN\]' "$LOG_FILE" || true
else
  log "No warnings/errors during post-create. Post-create completed."
fi