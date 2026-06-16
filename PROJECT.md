# llm-arch-insight

Early-stage Python project for re-familiarizing with neural network architectures and ML frameworks.

## Status

Skeleton only — `src/template/main.py` is the sole source file (a `Hello World` stub). No models, datasets, or experiments yet.

## Environment

| Item | Value |
|------|-------|
| Python | 3.12 (pinned via `.python-version`) |
| Package manager | `uv` |
| Virtual env | `.venv/` |
| IDE config | `.idea/` (JetBrains) |

## Dependencies (pyproject.toml)

- `pytest` — testing
- `ruff` — linting + formatting (line-length 120, rules E/F/I)
- `black` / `blacken-docs` — formatting (also applied to code blocks in docs)
- `isort`, `pycodestyle`, `pyflakes` — style enforcement
- `docker` — container tooling (future use)
- `vibepod` — (experimental/internal tooling)

## Commands

```bash
uv sync                          # install dependencies
uv run src/template/main.py      # run entry point

uv run pytest src/test           # run tests
uv run ruff check .              # lint
uv run ruff format .             # format
uv run pre-commit run --all-files  # run all pre-commit hooks manually
```

## Quality Gates (pre-commit, fail-fast)

1. Standard hygiene: trailing whitespace, EOF newline, BOM, mixed line endings, large files, private keys, case conflicts
2. AST validity check on all Python files
3. Debug-statement detection (`pdb`, `print`)
4. JSON/YAML validation
5. `blacken-docs` — formats Python code in markdown/rst/tex
6. `uv-lock` — keeps `uv.lock` in sync
7. `ruff-format` then `ruff-check` on all Python files
8. `pytest` + coverage threshold (≥80% line coverage) — triggered when files under `src/` change

## Project Layout

```
llm_arch_insight/
├── src/
│   └── template/
│       └── main.py          # stub entry point
├── pyproject.toml
├── uv.lock
├── .python-version          # 3.12
├── .pre-commit-config.yaml
└── CLAUDE.md                # guidance for Claude Code
```
