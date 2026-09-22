#!/usr/bin/env bash
set -euo pipefail

# render to a temporary directory and run checks on the rendered output (to catch bugs invisible in raw-source linting)
RENDER_DIR="/tmp/pc-render"
rm -rf "$RENDER_DIR"
cookiecutter . --no-input -o "$RENDER_DIR"
cd "$RENDER_DIR"/*/

# ruff check
echo "Running ruff check on rendered output..."
uv run ruff check .

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
find . -name '*.sh' -print0 | xargs -0 --no-run-if-empty uv run shellcheck
