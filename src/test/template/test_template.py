import tomllib
import traceback

import pytest


def _assert_baked(result):
    if result.exception is not None:
        traceback.print_exception(type(result.exception), result.exception, result.exception.__traceback__)
    assert result.exit_code == 0, f"Bake failed with exit code {result.exit_code}"
    assert result.exception is None, f"Bake raised an exception: {result.exception}"


# cookies fixture is provided by pytest-cookies
def test_bakes_with_defaults(cookies):
    result = cookies.bake()
    _assert_baked(result)
    assert result.project_path.is_dir()


def test_project_slug_works(cookies):
    result = cookies.bake(extra_context={"project_name": "Totally Unslugged Project"})
    _assert_baked(result)
    assert result.project_path.name == "totally_unslugged_project"
    assert (result.project_path / "src/totally_unslugged_project/__init__.py").is_file()


@pytest.mark.parametrize("model", ["qwen2.5-coder:14b", "none"])
def test_local_model_file_stripping(cookies, model):
    result = cookies.bake(extra_context={"local_model": model})
    _assert_baked(result)
    ask = result.project_path / "scripts/ask.sh"
    cont = result.project_path / ".continue"
    if model == "none":
        assert not ask.exists()
        assert not cont.exists()
    else:
        assert ask.exists()
        assert cont.exists()


@pytest.mark.parametrize("gpu", ["yes", "no"])
def test_gpu_block_preparation(cookies, gpu):
    result = cookies.bake(extra_context={"gpu_training": gpu})
    _assert_baked(result)
    compose = (result.project_path / ".devcontainer/docker-compose.yml").read_text()
    assert ("driver: nvidia" in compose) == (gpu == "yes")


@pytest.mark.parametrize("gpu", ["yes", "no"])
def test_rendered_pyproject_is_valid_toml(cookies, gpu):
    result = cookies.bake(extra_context={"gpu_training": gpu})
    _assert_baked(result)
    data = tomllib.loads((result.project_path / "pyproject.toml").read_text())

    assert data["project"]["name"] == result.project_path.name
    assert data["build-system"]["build-backend"] == "hatchling.build"
    assert any(d for d in data["tool"] if d.startswith("pytest"))
    assert "coverage-threshold" in data
    assert data["tool"]["coverage"]["report"]["fail_under"] == 80

    has_train_group = "train" in data.get("dependency-groups", {})
    has_torch_source = "torch" in data.get("tool", {}).get("uv", {}).get("sources", {})
    has_pytorch_index = any(
        idx.get("name") == "pytorch-cu126" for idx in data.get("tool", {}).get("uv", {}).get("index", [])
    )
    assert has_train_group == (gpu == "yes")
    assert has_torch_source == (gpu == "yes")
    assert has_pytorch_index == (gpu == "yes")


def test_scan_sh_static_when_none_local_model(cookies):
    result = cookies.bake(extra_context={"local_model": "none"})
    _assert_baked(result)
    scan_sh = result.project_path / "scripts" / "scan.sh"
    assert scan_sh.exists()

    scan = scan_sh.read_text()
    assert "--no-llm" in scan


@pytest.mark.parametrize("model", ["qwen2.5-coder:14b", "none"])
def test_continue_cli_install_gated_by_local_model(cookies, model):
    result = cookies.bake(extra_context={"local_model": model})
    _assert_baked(result)

    post_create = (result.project_path / ".devcontainer" / "post-create.sh").read_text()
    assert ("@continuedev/cli" in post_create) == (model != "none")
