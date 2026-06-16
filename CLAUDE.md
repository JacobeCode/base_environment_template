# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`llm-arch-insight` is an early-stage Python project for refamiliarizing with neural network architectures and frameworks. Currently a minimal skeleton under `src/`.

## Environment

- Python >=3.12 (managed via `uv`, see `uv.lock` and `.python-version`)
- Install dependencies: `uv sync`
- Run an entry point, e.g.: `uv run src/template/main.py`

## Commands

- Run tests: `uv run pytest src/test`
- Lint: `uv run ruff check .`
- Format: `uv run ruff format .`
- Run pre-commit hooks manually: `uv run pre-commit run --all-files`

## Structure

- `src/template/` — example/template module showing the project layout for new code.
- `src/test/` — test suite, run via pytest.

## Code style

- Ruff is configured with `line-length = 120` and rule sets `E`, `F`, `I` (pycodestyle errors, pyflakes, isort). `ruff-format` and `ruff-check --fix` run via pre-commit.
- Coverage thresholds (in `pyproject.toml`): line coverage minimum 80%.

## Pre-commit

Configured in `.pre-commit-config.yaml` (fail-fast, runs on `pre-commit` and `pre-merge-commit` stages):
- Standard hygiene checks (trailing whitespace, EOF fixer, YAML/JSON validation, debug statements, AST check, large files, private keys, etc.)
- `blacken-docs` — formats Python code blocks in markdown/rst/tex docs.
- `uv-lock` — keeps `uv.lock` in sync.
- `ruff-format` / `ruff-check` on Python files.
- `pytest` — runs `uv run pytest src/test`, triggered only when files under `src/` change.
