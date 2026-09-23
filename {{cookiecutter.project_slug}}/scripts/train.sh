#!/usr/bin/env bash
# for the trains local model is unloaded to free system RAM
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/logging.sh" train

MODEL="${LOCAL_MODEL:-{{cookiecutter.local_model}}}"
OLLAMA="${OLLAMA_HOST_URL:-http://ollama:11434}"

reload() {
    log "Warming $MODEL back up"
    curl -s "$OLLAMA/api/generate" -d "{\"model\":\"$MODEL\"}" >/dev/null \
        || warn "failed to reload $MODEL — run a scan/query to warm it manually"
}
trap reload EXIT

log "Unloading $MODEL to free system RAM for training"
curl -s "$OLLAMA/api/generate" -d "{\"model\":\"$MODEL\",\"keep_alive\":0}" >/dev/null \
    || warn "failed to unload $MODEL — it may still be holding RAM"

log "Running: $*"
"$@"
