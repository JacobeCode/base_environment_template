import traceback

import pytest


def _assert_baked(result):
    if result.exception is not None:
        traceback.print_exception(type(result.exception), result.exception, result.exception.__traceback__)
    assert result.exit_code == 0, f"Bake failed with exit code {result.exit_code}"
    assert result.exception is None, f"Bake raised an exception: {result.exception}"


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
