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


@pytest.mark.parametrize("monitoring", ["no", "yes"])
def test_monitoring_no_strips_monitoring_dir(tmp_path, monkeypatch, monitoring):
    monkeypatch.chdir(tmp_path)
    _touch("monitoring/prometheus.yml")
    post_gen.main("none", monitoring)
    assert os.path.exists("monitoring") == (monitoring == "yes")


SH = "#!/bin/bash\n"
# path -> (content, mode before, expected mode after)
CHMOD_CASES = {
    "scripts/run.sh": (SH, 0o644, 0o755),  # normal script
    "scripts/private.sh": (SH, 0o600, 0o700),  # no exec for group/others
    "scripts/groupexec.sh": (SH, 0o654, 0o755),  # owner lacked exec
    "scripts/already.sh": (SH, 0o750, 0o750),  # owner can exec: untouched
    "scripts/unreadable.sh": (SH, 0o200, 0o200),  # nothing to add
    "scripts/helper.sh": ("log() { :; }\n", 0o644, 0o644),  # no shebang
    "scripts/notes.txt": (SH, 0o644, 0o644),  # not *.sh
    "elsewhere/target.sh": (SH, 0o644, 0o644),  # symlink target, outside folders
    ".devcontainer/post-create.sh": (SH, 0o644, 0o755),
}


def test_make_scripts_executable_touches_only_what_it_should(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    for rel, (text, before, _) in CHMOD_CASES.items():
        f = tmp_path / rel
        f.parent.mkdir(exist_ok=True)
        f.write_text(text)
        f.chmod(before)
    (tmp_path / "scripts/link.sh").symlink_to("../elsewhere/target.sh")  # must not chmod the target

    post_gen.make_scripts_executable()

    actual = {rel: (tmp_path / rel).stat().st_mode & 0o777 for rel in CHMOD_CASES}
    assert actual == {rel: after for rel, (_, _, after) in CHMOD_CASES.items()}


def test_rm_failure_exits_nonzero(tmp_path, monkeypatch, capsys):
    monkeypatch.chdir(tmp_path)
    _touch("scripts/ask.sh")

    monkeypatch.setattr(os, "remove", Mock(side_effect=OSError("failure")))

    with pytest.raises(SystemExit) as exc_info:
        post_gen.rm("scripts", "ask.sh")
    assert exc_info.value.code == 1
    assert "failed to remove" in capsys.readouterr().err
