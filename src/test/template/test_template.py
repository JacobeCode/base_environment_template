"""Render the template across its option matrix and assert the output is correct."""

import tomllib

import pytest


def test_bakes_with_defaults(baked):
    result = baked()
    assert result.project_path.is_dir()


def test_project_slug_slugifies(baked):
    result = baked(project_name="My Cool Project")
    assert result.project_path.name == "my_cool_project"
    assert (result.project_path / "src" / "my_cool_project" / "__init__.py").is_file()


@pytest.mark.parametrize("model", ["qwen2.5-coder:14b", "none"])
def test_local_model_file_stripping(baked, model):
    """post_gen removes ask.sh + .continue ONLY when local_model == 'none'."""
    result = baked(local_model=model)
    ask = result.project_path / "scripts" / "ask.sh"
    cont = result.project_path / ".continue"
    if model == "none":
        assert not ask.exists()
        assert not cont.exists()
    else:
        assert ask.exists()
        assert cont.exists()


@pytest.mark.parametrize("gpu", ["yes", "no"])
def test_gpu_block_conditional(baked, gpu):
    """docker-compose GPU reservation appears iff gpu_usage == 'yes'."""
    result = baked(gpu_usage=gpu)
    compose = (result.project_path / ".devcontainer" / "docker-compose.yml").read_text()
    assert ("driver: nvidia" in compose) == (gpu == "yes")


@pytest.mark.parametrize("gpu", ["yes", "no"])
def test_ollama_gets_the_gpu_if_gpu_usage(baked, gpu):
    """gpu_usage=yes puts the nvidia reservation on BOTH dev and ollama (inside
    ollama's existing deploy.resources — a second `deploy:` key would be invalid
    YAML, and the CPU/memory limits must survive); gpu_usage=no leaves ollama
    CPU-only so the stack still comes up on a host without the NVIDIA toolkit."""
    import yaml

    result = baked(local_model="qwen2.5-coder:14b", gpu_usage=gpu)
    compose = yaml.safe_load((result.project_path / ".devcontainer" / "docker-compose.yml").read_text())
    res = compose["services"]["ollama"]["deploy"]["resources"]
    assert "limits" in res
    assert ("reservations" in res) == (gpu == "yes")
    assert ("deploy" in compose["services"]["dev"]) == (gpu == "yes")


def test_model_script_and_recipes_follow_local_model(baked):
    with_model = baked(local_model="qwen2.5-coder:14b", gpu_usage="yes")
    assert (with_model.project_path / "scripts" / "model.sh").exists()
    just = (with_model.project_path / "justfile").read_text()
    assert "model-off:" in just and "model-on:" in just
    assert "train.sh" not in just

    without = baked(local_model="none")
    assert not (without.project_path / "scripts" / "model.sh").exists()


@pytest.mark.parametrize("gpu", ["yes", "no"])
def test_rendered_pyproject_is_valid_toml(baked, gpu):
    """
    The templated pyproject must parse as valid TOML AND have the right
    sections present/absent per branch — parsing alone doesn't catch a
    {% if %} that silently drops a section it shouldn't, and a bake with no
    override never exercises the gpu_usage=yes branch at all.
    """
    result = baked(gpu_usage=gpu)
    data = tomllib.loads((result.project_path / "pyproject.toml").read_text())

    # Always present, regardless of gpu_usage
    assert data["project"]["name"] == result.project_path.name
    assert data["build-system"]["build-backend"] == "hatchling.build"
    assert any(d.startswith("pytest") for d in data["dependency-groups"]["dev"])
    assert "coverage-threshold" in data  # top-level table, no `tool.` prefix
    assert data["tool"]["coverage"]["report"]["fail_under"] == 80

    # gpu_usage-gated sections: present ONLY when gpu == "yes"
    has_train_group = "train" in data.get("dependency-groups", {})
    has_torch_source = "torch" in data.get("tool", {}).get("uv", {}).get("sources", {})
    has_pytorch_index = any(
        idx.get("name") == "pytorch-cu126" for idx in data.get("tool", {}).get("uv", {}).get("index", [])
    )
    assert has_train_group == (gpu == "yes")
    assert has_torch_source == (gpu == "yes")
    assert has_pytorch_index == (gpu == "yes")


def test_scan_sh_static_only_when_none(baked):
    result = baked(local_model="none")
    scan = (result.project_path / "scripts" / "scan.sh").read_text()
    assert "--no-llm" in scan


@pytest.mark.parametrize("model", ["qwen2.5-coder:14b", "none"])
def test_continue_cli_install_gated_by_local_model(baked, model):
    """post-create.sh installs the Continue CLI iff a local model is configured."""
    result = baked(local_model=model)
    post_create = (result.project_path / ".devcontainer" / "post-create.sh").read_text()
    assert ("@continuedev/cli" in post_create) == (model != "none")
