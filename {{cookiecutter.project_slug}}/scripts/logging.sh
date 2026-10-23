#!/usr/bin/env bash

# managing shared logging helpers - usage with source with a log name:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/logging.sh" scan
# source to persist on current build
# provides: log / warn / err, plus $LOG_FILE and $WARN_COUNT
LOG_DIR="${LOG_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/logs}"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/${1:-script}.log"
: > "$LOG_FILE" # clean the file - keep the latest

WARN_COUNT=0

_ts()   { date +'%Y-%m-%dT%H:%M:%S%z'; }
log()   { echo "[$(_ts)] [INFO] $*" | tee -a "$LOG_FILE"; }
warn()  { WARN_COUNT=$((WARN_COUNT + 1)); echo "[$(_ts)] [WARN]  $*" | tee -a "$LOG_FILE" >&2; }
err()   { echo "[$(_ts)] [ERROR] $*" | tee -a "$LOG_FILE" >&2; }
