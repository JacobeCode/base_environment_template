#!/usr/bin/env bash
set -euo pipefail

# shared logging sourcing - writes to logs/post-create.log (last run save)
# shellcheck source=../scripts/logging.sh
# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/logging.sh" post-create

# setting on "strict, fail-fast" -euo pipefail
log "Running post-create script..."

# ---------- PIN VERSION ----------

# empty value for latest
UV_VERSION="0.13.1"
JUST_VERSION="1.59.0"
CODEGRAPH_VERSION="1.6.2"
HEADROOM_VERSION="0.41.0"
CONTINUE_CLI_VERSION="2.0.0"

# ---------- UV ----------

log "Installing uv and syncing project dependencies..."

# uv + project dependencies
curl -LsSf https://astral.sh/${UV_VERSION:+$UV_VERSION/}install.sh | sh
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
  just_args=(--to "$HOME/.local/bin")
  [ -n "$JUST_VERSION" ] && just_args+=(--tag "$JUST_VERSION")
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- "${just_args[@]}" \
        || warn "just install failed — use the scripts/*.sh files directly instead of just <recipe>"
fi

# ---------- CLAUDE CONFIG VOLUME OWNERSHIP ----------

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
if [ ! -w "$CLAUDE_DIR" ]; then
  case "$CLAUDE_DIR" in
    /home/*/.claude)
      log "Fixing ownership of $CLAUDE_DIR"
      sudo chown -R "$(id -u):$(id -g)" "$CLAUDE_DIR" \
        || warn "could not chown $CLAUDE_DIR - claude plugins/MCP installs will fail"
      ;;
    *)
      warn "refusing to chown unexpected path: $CLAUDE_DIR - fix its ownership manually"
      ;;
  esac
fi

# ---------- AGENT CODING TOOLS ----------

# CodeGraph — local code knowledge graph, exposed to Claude Code over MCP.
log "Installing codegraph..."

npm install -g "@colbymchenry/codegraph${CODEGRAPH_VERSION:+@$CODEGRAPH_VERSION}" \
  || warn "codegraph npm install failed - codegraph steps below will fail"
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
uv tool install "headroom-ai[mcp]${HEADROOM_VERSION:+==$HEADROOM_VERSION}" || warn "Failed to install headroom-ai"
headroom mcp install || warn "Failed to install headroom MCP plugin"

# ---------- CONTINUE CLI ----------

# CLI Continue for local model for capabilities similar to e.g. Claude
{%- if cookiecutter.local_model != "none" %}
npm install -g "@continuedev/cli${CONTINUE_CLI_VERSION:+@$CONTINUE_CLI_VERSION}" || warn "Continue CLI install failed"

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