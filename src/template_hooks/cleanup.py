"""Post-generation cleanup logic. Importable, so it's unit-testable with real coverage.

Jinja can conditionally omit file *contents* but not whole *files* — every file in
the template renders unconditionally. Making a file disappear for certain option
combinations means deleting it here, in post_gen, instead.
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
        print(f"[post_gen] failed to remove {path}: {e}", file=sys.stderr)
        sys.exit(1)


# Current validation is not needed, but passed for further iteration in the future.
# if LOCAL_MODEL not in VALID:
#     fail(f"unexpected local_model={LOCAL_MODEL!r}; expected one of {sorted(VALID)}")


def run(local_model: str) -> None:
    """Strip local-model-only files when the user chose no local model."""
    if local_model == "none":
        # docker-compose.yml, devcontainer.json, scan.sh, pyproject guard their own
        # local-model blocks with Jinja; only whole standalone files are removed here.
        rm("scripts", "ask.sh")
        rm("scripts", "chat.sh")
        rm(".continue")
    print(f"[post_gen] local_model={local_model}")
