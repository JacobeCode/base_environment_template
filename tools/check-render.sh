#!/usr/bin/env bash
set -euo pipefail

EXCLUDE_DIRS=(\
  '.venv'
  'venv'
  'env'
  '.tox'
  '.nox'
  'site-packages'
  'node_modules'
  '__pycache__'
  '.git'
  'build'
  'dist'
)

# render to a temporary directory and run checks on the rendered output (to catch bugs invisible in raw-source linting)
RENDER_DIR="/tmp/pc-render"
rm -rf "$RENDER_DIR"
cookiecutter . --no-input -o "$RENDER_DIR"
cd "$RENDER_DIR"/*/

# ruff check
echo "Running ruff check on rendered output..."
RUFF_EXCLUDE_ARGS=()
for dir_name in "${EXCLUDE_DIRS[@]}"; do
  RUFF_EXCLUDE_ARGS+=(--exclude "$dir_name")
done
uv run ruff check . "${RUFF_EXCLUDE_ARGS[@]}"

# toml check
echo "Running toml check on rendered output..."
python3 -c "
import pathlib, tomllib
for f in pathlib.Path('.').rglob('*.toml'):
    tomllib.loads(f.read_text())
    print(f'Parsed TOML file OK: {f}')
"

# sh check
echo "Running shellcheck on rendered output..."
FIND_NAME_ARGS=()
for dir_name in "${EXCLUDE_DIRS[@]}"; do
  FIND_NAME_ARGS+=(-name "$dir_name" -o)
done
find . \( -type d \( "${FIND_NAME_ARGS[@]}" -false \) -prune \) -o -name '*.sh' -print0 | xargs -0 --no-run-if-empty uv run --with shellcheck-py shellcheck
