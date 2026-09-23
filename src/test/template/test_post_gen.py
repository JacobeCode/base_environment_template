"""
As an exception the tests for the post_gen_project.py hook are executed on specially imported file, not module.
"""

import importlib.util
import os
from pathlib import Path
from unittest.mock import Mock

import pytest

# hook path is relative to the test file, not the project root
HOOK_PATH = Path(__file__).resolve().parents[3] / "hooks" / "post_gen_project.py"
_spec = importlib.util.spec_from_file_location("post_gen_project", HOOK_PATH)

# name != __main__ (nothing executes)
post_gen = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(post_gen)


def _touch(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").close()


def test_none_strips_local_files(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")
    _touch("scripts/chat.sh")
    os.makedirs(".continue")
    post_gen.main("none")
    assert not os.path.exists("scripts/ask.sh")
    assert not os.path.exists("scripts/chat.sh")
    assert not os.path.exists(".continue")


def test_model_keeps_local_files(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")
    _touch("scripts/chat.sh")
    os.makedirs(".continue")
    post_gen.main("qwen2.5-coder:14b")
    assert os.path.exists("scripts/ask.sh")
    assert os.path.exists("scripts/chat.sh")
    assert os.path.exists(".continue")


def test_rm_failure_exits_nonzero(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")

    monkeypatch.setattr(os, "remove", Mock(side_effect=OSError("failure")))

    with pytest.raises(SystemExit) as exc_info:
        post_gen.rm("scripts", "ask.sh")
    assert exc_info.value.code == 1
    assert "failed to remove" in capsys.readouterr().err
