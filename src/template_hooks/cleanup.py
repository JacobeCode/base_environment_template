"""
Runs in the generated project.
Strips local-model files when local_model == 'none' as `.cookiecutter.json` is not a Jinja template
and cannot conditionally remove files.
"""

import os
import shutil
import sys


def rm(*parts: str) -> None:
    try:
        path = os.path.join(*parts)
        if os.path.isfile(path):
            os.remove(path)
            print(f"[post_gen] removed file {path}")
        elif os.path.isdir(path):
            shutil.rmtree(path)
            print(f"[post_gen] removed dir {path}")
    except OSError as e:
        print(f"[post_gen] failed to remove local_model files {path}: {e}", file=sys.stderr)
        sys.exit(1)


# Current validation is not needed, but passed for further iteration in the future.
# if LOCAL_MODEL not in VALID:
#     fail(f"unexpected local_model={LOCAL_MODEL!r}; expected one of {sorted(VALID)}")


def run(local_model: str) -> None:
    if local_model == "none":
        # No local server: drop the terminal helper and the editor client for it.
        rm("scripts", "ask.sh")
        rm(".continue")
    print(f"[post_gen] local_model={local_model}")
