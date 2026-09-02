import os

from template_hooks.cleanup import run


def _touch(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").close()


def test_none_strips_local_files(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")
    os.makedirs(".continue")
    run("none")
    assert not os.path.exists("scripts/ask.sh")
    assert not os.path.exists(".continue")


def test_model_keeps_local_files(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")
    os.makedirs(".continue")
    run("qwen2.5-coder:14b")
    assert os.path.exists("scripts/ask.sh")
    assert os.path.exists(".continue")
