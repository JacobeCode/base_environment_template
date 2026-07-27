#!/usr/bin/env bash
set -euo pipefail
MODEL="${LOCAL_MODEL:-{{cookiecutter.local_model}}}"
OLLAMA="${OLLAMA_HOST_URL:-http://ollama:11434}"
PROMPT="$*"

if [ -z "$PROMPT"]; then
    echo "usage: ./scripts/ask.sh <your question>" >&2
    exit 1
fi

command -v jq >/dev/null || { echo "ask.sh needs jq (apt install jq)" >&2; exit 1; }

# jq build for JSON body, args non-malformed handling -> stream: false for whole response completion
body="$(jq -n --arg m "$MODEL" --arg p "$PROMPT" '{model:$m, prompt:$p, stream:false}')"

# -f for catching fails on HTTP errors
if ! resp="$(curl -sf "$OLLAMA/api/generate" -d "$body")"; then
    echo "ask.sh: request to $OLLAMA failed — is the ollama service running?" >&2
    echo "  try: docker compose -f .devcontainer/docker-compose.yml ps" >&2
    exit 1
fi

# add answer block