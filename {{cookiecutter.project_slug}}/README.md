# {{ cookiecutter.project_name }}

{{ cookiecutter.project_description }}

## Setup

Open in VS Code → "Reopen in Container." `uv sync` and the pre-commit hooks run automatically on container start (see `.devcontainer/post-create.sh`).

## Commands

Run `just --list` for the full set.

See `CLAUDE.md` for agent-specific conventions and the security/tooling setup.

## Status

Skeleton only — `src/{{ cookiecutter.project_slug }}/main.py` is the sole source file (a stub entry point). No models, datasets, or experiments yet.

## Environment

| Item | Value |
|------|-------|
| Python | {{ cookiecutter.python_version }} (pinned via `.python-version`) |
| Package manager | `uv` |
| Virtual env | `.venv/` |
| Dev container | Docker Compose (`.devcontainer/`) — services: `dev`{%- if cookiecutter.local_model != "none" %}, `ollama`, `model-init`{%- endif %} |
{%- if cookiecutter.gpu_training == "yes" %}
| GPU | passthrough on `dev` (NVIDIA Container Toolkit required on host) |
{%- endif %}

## Dependencies (`pyproject.toml`)

- `pytest` + `pytest-cov` — testing + total coverage gate
- `coverage-threshold` — per-file coverage floor
- `ruff` — linting + formatting (line-length 100, rules `E`/`F`/`I`/`UP`/`B` — replaces black/isort/pycodestyle/pyflakes as separate tools)
- `pre-commit` — the hooks below, installed automatically on container start
{%- if cookiecutter.gpu_training == "yes" %}
- `torch` / `torchvision` — CUDA build, from the `pytorch-cu126` index (verify against `pytorch.org/get-started/locally/`, not PyPI's default CPU build)
{%- endif %}

## Setup

Open in VS Code → "Reopen in Container." `uv sync` and the pre-commit hooks run automatically via `.devcontainer/post-create.sh`.

## Commands

```bash
uv sync                                              # install dependencies
uv run python src/{{ cookiecutter.project_slug }}/main.py   # run the entry point

just test                                            # uv run pytest (+ coverage)
just lint                                            # ruff check --fix, then ruff format
uv run pre-commit run --all-files                    # run all hooks manually
{%- if cookiecutter.local_model != "none" %}
just scan [target]                                   # SkillSpector (static + LLM)
just ask <question>                                  # one-shot local-model query
./scripts/chat.sh                                    # local-model chat with memory
{%- else %}
just scan [target]                                   # SkillSpector (static-only)
{%- endif %}
{%- if cookiecutter.gpu_training == "yes" %}
just train <cmd>                                     # evicts local model, runs cmd, reloads after
just gpu                                              # verify CUDA is visible
{%- endif %}
```

Run `just --list` for the full set.

## Quality gates (pre-commit)

1. Hygiene: trailing whitespace, EOF newline, large files, private keys, debug-statement detection (excluded on `main.py`'s intentional entry-point `print()`)
2. JSON/YAML validation
3. `ruff-check` (`--fix`), then `ruff-format` — in that order, since fixes can produce code that needs reformatting
4. `uv-lock` — keeps `uv.lock` in sync with `pyproject.toml`
5. `blacken-docs` — formats Python code blocks in markdown docs
6. `skillspector-static` — {%- if cookiecutter.local_model != "none" %} static-only (`--no-llm`) scan of `./skills/`; the LLM pass is on-demand (`just scan`), never on every commit{%- else %} static scan of `./skills/` (no local model configured, so static-only regardless){%- endif %}
7. `pytest` (total coverage, `fail_under`) → `coverage json` → `coverage-threshold` (per-file floor) — in that order, since `coverage-threshold` reads the JSON report

This is not `fail_fast` — a single commit attempt reports every failing hook, not just the first.

## Project layout

```
{{ cookiecutter.project_slug }}/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── docker-compose.yml
│   └── post-create.sh
{%- if cookiecutter.local_model != "none" %}
├── .continue/
│   └── config.yaml
{%- endif %}
├── src/{{ cookiecutter.project_slug }}/
│   ├── __init__.py
│   └── main.py                # stub entry point
├── tests/
│   └── test_smoke.py
├── scripts/
│   ├── logging.sh             # shared log/warn/err
│   ├── scan.sh
{%- if cookiecutter.local_model != "none" %}
│   ├── ask.sh
│   ├── chat.sh
{%- endif %}
{%- if cookiecutter.gpu_training == "yes" %}
│   └── train.sh
{%- endif %}
├── logs/                       # gitignored, truncated per run
├── skills/
├── .pre-commit-config.yaml
├── .github/workflows/
│   ├── skill-scan.yml
│   └── ci.yml
├── .gitignore
├── .dockerignore
├── .env.example
├── justfile
├── CLAUDE.md                   # guidance for Claude Code
├── pyproject.toml
├── uv.lock
├── .python-version
└── README.md
```

See `CLAUDE.md` for agent-specific conventions and the security/tooling setup.
