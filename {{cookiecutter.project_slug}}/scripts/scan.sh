#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/logging.sh" scan
TARGET="${1:-./skills/}"

# SkillSpector exit codes: 
# 0 = score at/below threshold, 
# 1 = score ABOVE threshold (do not use),
# 2 = the scan itself broke. 
# Exit 1 is a verdict, not a failure to run - never downgrade it to a warning.

log "Static scan (fast, always-on, no model): $TARGET"
rc=0
skillspector scan "$TARGET" --no-llm --format terminal || rc=$?
case "$rc" in
    0) ;;
    1) err "static scan: risk score above threshold (exit 1) - do not use $TARGET"; exit 1 ;;
    *) err "static scan did not complete (exit $rc)"; exit "$rc" ;;
esac
{%- if cookiecutter.local_model != "none" %}

log "Full scan with local LLM ({{cookiecutter.local_model}}, already warm)"
rm -f results.sarif
rc=0
skillspector scan "$TARGET" --format sarif --output results.sarif || rc=$?
case "$rc" in
    0) log "results.sarif written — open with the SARIF Viewer extension" ;;
    1) err "LLM scan: risk score above threshold (exit 1) - do not use $TARGET (see results.sarif)"; exit 1 ;;
    *) warn "LLM scan could not run (exit $rc) — no results.sarif produced (static scan results above still apply)" ;;
esac
{%- endif %}