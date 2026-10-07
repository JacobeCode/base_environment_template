#!/usr/bin/env bash
set -euo pipefail

# script for local model managment through Ollama on | off | status
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/logging.sh" model

# variables access to model
MODEL="${LOCAL_MODEL:-{{cookiecutter.local_model}}}"
OLLAMA="${OLLAMA_HOST_URL:-http://ollama:11434}"

case "${1:-}" in
  off)
    log "Unloading $MODEL"
        curl -sf "$OLLAMA/api/generate" -d "{\"model\":\"$MODEL\",\"keep_alive\":0}" >/dev/null \
            || { warn "failed to unload $MODEL — is ollama up?"; exit 1; }
        ;;
  on)
    log "Loading $MODEL"
		curl -sf "$OLLAMA/api/generate" -d "{\"model\":\"$MODEL\"}" >/dev/null \
            || { warn "failed to load $MODEL — is ollama up?"; exit 1; }
        ;;
	status)
        curl -sf "$OLLAMA/api/ps" || { warn "ollama unreachable"; exit 1; }
        echo
        ;;
    *)
		echo "usage: $0 off|on|status" >&2
        exit 2
        ;;
esac
