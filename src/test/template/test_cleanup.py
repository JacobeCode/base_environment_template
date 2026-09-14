import os
from unittest.mock import Mock

import pytest

from template_hooks.cleanup import rm, run


def _touch(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").close()


def test_none_strips_local_files(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")
    _touch("scripts/chat.sh")
    os.makedirs(".continue")
    run("none")
    assert not os.path.exists("scripts/ask.sh")
    assert not os.path.exists("scripts/chat.sh")
    assert not os.path.exists(".continue")


def test_model_keeps_local_files(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")
    _touch("scripts/chat.sh")
    os.makedirs(".continue")
    run("qwen2.5-coder:14b")
    assert os.path.exists("scripts/ask.sh")
    assert os.path.exists("scripts/chat.sh")
    assert os.path.exists(".continue")


def test_rm_failure_exits_nonzero(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")

    monkeypatch.setattr(os, "remove", Mock(side_effect=OSError("failure")))

    with pytest.raises(SystemExit) as exc_info:
        rm("scripts", "ask.sh")
    assert exc_info.value.code == 1
    assert "failed to remove" in capsys.readouterr().err
