#!/usr/bin/env bash
set -euo pipefail
MODEL="${LOCAL_MODEL:-{{cookiecutter.local_model}}}"
OLLAMA="${OLLAMA_HOST_URL:-http://ollama:11434}"
PROMPT="$*"

# shared logging sourcing - writes to logs/ask.log (last run save)
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/logging.sh" ask

if [ -z "$PROMPT" ]; then
    echo "usage: ./scripts/ask.sh <your question>" >&2
    exit 1
fi

command -v jq >/dev/null || { echo "ask.sh needs jq (apt install jq)" >&2; exit 1; }

log "asking $MODEL: $PROMPT"

# jq build for JSON body, args non-malformed handling -> stream: false for whole response completion
body="$(jq -n --arg m "$MODEL" --arg p "$PROMPT" '{model:$m, prompt:$p, stream:false}')"

# -f for catching fails on HTTP errors
if ! resp="$(curl -sf "$OLLAMA/api/generate" -d "$body")"; then
    warn "ask.sh: request to $OLLAMA failed — is the ollama service running?" >&2
    log "  try: docker compose -f .devcontainer/docker-compose.yml ps" >&2
    exit 1
fi

# An API error must not be printed as if it were the answer, and must not exit 0.
api_error="$(echo "$resp" | jq -r '.error // empty')"
if [ -n "$api_error" ]; then
    warn "ollama returned an error: $api_error"
    exit 1
fi
# The `// empty` guard keeps a malformed reply from printing a bare "null".
answer="$(echo "$resp" | jq -r '.response // empty')"

# handle errors and fail requests in processing the answer
if [ -z "$answer" ]; then
    warn "ask.sh: no response from model '$MODEL' - check the name with:" >&2
    log "  docker compose -f .devcontainer/docker-compose.yml exec ollama ollama list" >&2
    exit 1
fi

echo "$answer"
log "answered ($(printf '%s' "$answer" | wc -c) chars)"
