# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`{{ cookiecutter.project_slug }}` - {{ cookiecutter.project_description }}

## Environment

- **Dev container**: Docker Compose–based devcontainer (`.devcontainer/`)
    - services: `dev` (this container)
    {%- if cookiecutter.local_model != "none" %}
    - `ollama` (local model, CPU-served),
    - `model-init` (one-shot model pull)
    {%- endif %}. 

Open in VS Code → "Reopen in Container."

- Python >={{ cookiecutter.python_version }} (managed via `uv`, see `uv.lock` and `pyproject.toml`)
- Install dependencies: `uv sync` (also runs automatically via `post-create.sh` on container start)

{%- if cookiecutter.gpu_training == "yes" %}
- GPU training: the `dev` service has GPU passthrough
{%- if cookiecutter.local_model != "none" %}; 
- `ollama` is CPU-only by design — no VRAM contention
{%- endif %}. 
Verify with `just gpu`.
{%- endif %}

## Commands

- Run tests: `just test`
- Lint + format: `just lint`
- Run pre-commit hooks manually: `uv run pre-commit run --all-files`
{%- if cookiecutter.local_model != "none" %}
- Scan skills: `just scan [target]` (static always; LLM pass uses the local model)
- Ask the local model (one-shot): `just ask <question>`
- Chat with memory: `./scripts/chat.sh`, or the Continue CLI (`cn`) — both use `.continue/config.yaml`
{%- else %}
- Scan skills: `just scan [target]` (static-only — no local model configured)
{%- endif %}

## Structure

- `src/{{ cookiecutter.project_slug }}/` — the package.
- `tests/` — test suite.
- `scripts/` 
    - `scan.sh` (SkillSpector)
    {%- if cookiecutter.local_model != "none" %}, 
    - `ask.sh`/`chat.sh` (local model)
    {%- endif %}
    {%- if cookiecutter.gpu_training == "yes" %}
    - `train.sh` (GPU coexistence){%- endif %}
    - `_logging.sh` (shared log/warn/err, sourced by the others).
- `skills/` — third-party agent skills. **Every skill here is scanned by SkillSpector before use** — see Security below.
- `logs/` — per-script run logs. Gitignored; truncated at the start of each run, so only the most recent run is kept.
{%- if cookiecutter.local_model != "none" %}
- `.continue/config.yaml` — points Continue (editor extension + `cn` CLI) at the local model.
{%- endif %}

## Code style

- Ruff: `line-length = 120`, rule sets `E`, `F`, `I`, `UP`, `B`.
- Coverage — two separate gates:
  - Total: `[tool.coverage.report] fail_under` — enforced automatically via `pytest`'s `--cov`.
  - Per-file: `coverage-threshold` (separate tool; top-level `[coverage-threshold]` table) — reads `coverage.json`, so it's `coverage json -q && coverage-threshold`, not standalone.


## Pre-commit

Configured in `.pre-commit-config.yaml` (runs on `pre-commit` and `pre-merge-commit` stages):
- Hygiene: JSON/YAML checks, EOF fixer, trailing whitespace, private-key detection, large-file guard, debug statements, AST check, etc.
- `ruff-check` (`--fix`) then `ruff-format`.
- `skillspector-static` — static-only (`--no-llm`) scan of `./skills/`; the LLM pass is on-demand (`just scan`), never on every commit.
- `pytest` (total coverage) → `coverage json` → `coverage-threshold` (per-file), in that order.
- `blacken-docs` — formats Python code blocks in markdown/rst/tex docs.
- `uv-lock` — keeps `uv.lock` in sync.

## Security

- Third-party skills in `./skills/` are gated by SkillSpector. Contract: exit `0` = SAFE/CAUTION, exit `1` = DO_NOT_INSTALL, exit `2` = scan error. Don't bypass a failing scan.
- Don't run with `--dangerously-skip-permissions`.
- Agent tooling: CodeGraph (query the graph before reading files to understand structure — this is where its value is realized), Ponytail (write-less-code discipline), Headroom (token compression). Third-party; pinned versions in `post-create.sh`.

## Style

- Prefer the standard library and native features over new dependencies.
- Smallest change that works; don't add speculative abstraction.
- Never sacrifice input validation, error handling, security, or accessibility.

{%- if cookiecutter.local_model != "none" %}
## Local model
- Served by the `ollama` service (CPU, warm by default — `OLLAMA_KEEP_ALIVE=-1`) so scans/chat are instant, no cold start.
{%- if cookiecutter.gpu_training == "yes" %}
- Only evicted during `just train` (frees system RAM for training's host-side footprint; VRAM is untouched — training and the model never contend for GPU memory).
{%- endif %}
{%- endif %}
