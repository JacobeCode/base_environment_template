#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/_logging.sh" scan
TARGET="${1:-./skills/}"

log "Static scan (fast, always-on, no model): $TARGET"
skillspector scan "$TARGET" --no-llm --format terminal

# renders only if local_model is available
{%- if cookiecutter.local_model != "none" %}
rm -f results.sarif # delete previous run file
if skillspector scan "$TARGET" --format sarif --output results.sarif; then
    log "results.sarif written — open with the SARIF Viewer extension"
else
    warn "LLM scan failed — no results.sarif produced (static scan results above still apply)"
fi
{%- endif %}