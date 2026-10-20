# base_environment_template

Cookiecutter templates for dev environments: **tools for the IDE + a Docker Compose dev container** that you can generate in one command and reopen in VS Code.

This repository is the **template**, not a generated project. Everything under `{{cookiecutter.project_slug}}/` is rendered by Cookiecutter; everything outside it (hooks, tests, CI, lint config) is tooling for the template itself.

> **Status:** under active development. CI renders every option combination and lints the output, but not every path has been run end to end on real hardware. See [TODO](#todo).

## What you get

A Debian dev container (Docker Compose-based devcontainer) with two independent layers:

**Layer 1: agentic coding (always on)**
- [Claude Code](https://code.claude.com/) with three helper tools installed automatically by `post-create.sh`:
  - **CodeGraph**: local code knowledge graph (retrieval)
  - **Headroom**: input-token compression
  - **Ponytail**: "write the least code" skill (output discipline)
- `uv` for Python and dependencies, `just` as the command runner, `pre-commit` hooks, `ruff`, `pytest` with coverage gates, ShellCheck on the scripts.

**Layer 2: scanning and local assist (optional, chosen at generation time)**
- [SkillSpector](https://github.com/NVIDIA/skillspector) to security-scan agent skills (`just scan`).
- A local code model served by Ollama (`qwen2.5-coder:14b`/`7b` or `deepseek-coder-v2:16b`), used by `ask.sh`, Continue (editor and CLI) and SkillSpector's LLM pass.
- Optional GPU access for training (and for the model).
- Optional usage/cost dashboard (Prometheus, Loki, Grafana) fed by Claude Code's own OpenTelemetry export.

The two layers share the container but nothing at runtime: the local model never touches Claude Code, and the agent tools never touch SkillSpector.

A second, non-Docker template (for projects that run directly on the host, with a hardened Claude Code security layer instead of container isolation) is planned alongside this one.

## Requirements

- Docker with Compose, and VS Code with the Dev Containers extension.
- `uv` (or `pipx`) to run Cookiecutter.
- For `gpu_usage=yes`: an NVIDIA GPU, a recent host driver, and the NVIDIA Container Toolkit. On WSL2 the driver is the Windows one.
- Enough RAM for the model you pick. The 14b model is about 9 GB; with WSL2, set the VM memory in `%UserProfile%\.wslconfig` and leave headroom for Windows.

## Quick start

```bash
# Generate a project (interactive prompts)
uv run cookiecutter git@github.com:JacobeCode/base_environment_template.git

# or non-interactive
uv run cookiecutter git@github.com:JacobeCode/base_environment_template.git --no-input \
    project_name="my-project" local_model="qwen2.5-coder:14b" gpu_usage=no monitoring=no guardrails=no

cd my_project
git init
code .            # then: "Reopen in Container"
```

On the first container start `post-create.sh` runs `uv sync`, installs the tools, and registers the pre-commit hooks (this needs a git repo, hence `git init`). The agent-tool steps need Claude Code to be logged in, so on a fresh container:

```bash
claude login
bash .devcontainer/post-create.sh      # idempotent; retries only what failed
```

Logs for each script are written to `logs/<name>.log` (overwritten on every run).

## Options (`cookiecutter.json`)

| Variable | Values | Effect |
|---|---|---|
| `project_name` | free text | Becomes the slug, container name and package directory. |
| `project_description` | free text | Rendered into `CLAUDE.md` and the generated `README.md`. |
| `author` | free text | Package metadata. |
| `python_version` | `3.14` (default) | Python version managed by `uv`. |
| `cuda_version` | `cu130` (default), `cu132`, `cu134`, `cu126` | (`gpu_usage=yes`) PyTorch CUDA wheel index. Must match your GPU and driver; |
| `local_model` | `qwen2.5-coder:14b` (default), `qwen2.5-coder:7b`, `deepseek-coder-v2:16b`, `none` | The whole local-model layer. `none` removes Ollama, the model pull, `ask.sh`/`model.sh` and the Continue config; SkillSpector then runs static-only. |
| `gpu_usage` | `no` (default), `yes` | `yes` gives the dev container the NVIDIA GPU for PyTorch/CUDA, and gives `ollama` the GPU too when a model is configured. It is chosen at generation time; there is no auto-detection. |
| `monitoring` | `no` (default), `yes` | Renders the Prometheus/Loki/Grafana stack and the telemetry variables. It is off at runtime until you ask for it. |
| `guardrails` | `no` (default), `yes` | Puts a guardrails service in front of the local model. A no-op if `local_model=none`. |

## Day-to-day commands (in a generated project)

```bash
just            # list commands
just test       # pytest with coverage
just lint       # ruff check --fix + format
just scan       # SkillSpector: static + local LLM pass
just ask "..."  # one-shot question to the local model
just gpu        # (gpu_usage=yes) check CUDA from PyTorch
just model-off  # (gpu_usage=yes + local model) free the model's VRAM before training
just model-on   # load it back afterwards
just monitor-up / monitor-down / monitor-open   # (monitoring=yes) dashboard at localhost:3000
```

### Sharing the GPU between the model and training

The model stays warm on the GPU by default. Before a training run, free the VRAM by hand with `just model-off`; reload with `just model-on` afterwards. `model-off` unloads the model's weights only; the `ollama` container keeps running, idle. Anything that talks to the model during training (Continue autocomplete, a scan) will load it again, so close those or stop the container from the host (`docker compose stop ollama`).

### Monitoring

Claude Code exports its own metrics and events (cost, tokens, tool calls, by model) over OpenTelemetry straight into Prometheus and Loki; Grafana shows them. Prompt and response text is never captured unless you opt in. The local model is **not** monitored yet (see TODO). The stack's containers carry a Compose profile, so a plain `docker compose up` does not start them.

## What a generated project contains (abridged)

```
.devcontainer/      devcontainer.json, docker-compose.yml, post-create.sh
scripts/            scan.sh, ask.sh , model.sh, logging.sh
.continue/          config.yaml for the Continue extension (symlinked into ~/.continue)
monitoring/         Prometheus + Grafana config (monitoring=yes)
guardrails/         guardrails service (guardrails=yes)
src/, src/test/        your code and tests
pyproject.toml      dependencies (declared here, pinned in uv.lock, installed into .venv)
justfile, CLAUDE.md, .env / .env.example, .pre-commit-config.yaml, .github/workflows/
```

## Working on the template itself

```
hooks/post_gen_project.py     removes files for features you did not select
src/test/template/            unit test for the hook + bake tests (pytest-cookies)
tools/check-render.sh         renders the defaults and lints the output (ruff, TOML, ShellCheck)
.github/workflows/template-ci.yml   renders the option matrix and validates each result
```

```bash
uv sync
uv run pre-commit install
uv run pytest                 # unit + bake tests, with coverage gates
bash tools/check-render.sh    # render + lint the output
```

The template source is full of Jinja (`{{ }}`, `{% %}`), which is not valid Python, TOML, YAML or bash. Linters therefore skip the templated tree and run against the **rendered** output instead.

## TODO

1. Write useful tools and plugins
2. ~~Add `brew`, and install `uv` through `brew`~~ ✅
3. ~~`uv sync` and deploy instructions~~ ✅
4. ~~Proper Cookiecutter install for project deployment~~ ✅
5. Proper setup for VS Code (autosave etc.)
6. ~~Fix logging in `post-create.sh`~~ ✅
7. ~~Check bash scripts with linters~~ ✅
8. ~~Check the train specification file~~ ✅
9. ~~Check the `.continue` configuration~~ ✅
10. ~~Add a test for `rm` in `post_gen` for a whole directory~~ ✅

**Also deferred:** monitoring of the local model's token counts and latency (needs a proxy in front of Ollama, or logging in `ask.sh`), and a Grafana dashboard JSON (`monitoring/grafana/dashboards/claude-code.json`) built against the real metric names.
