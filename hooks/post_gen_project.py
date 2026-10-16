"""
Post-generation cleanup logic. Importable, so it's unit-testable with real coverage.

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


def _has_shebang(path: str) -> bool:
    with open(path, "rb") as fh:
        return fh.read(2) == b"#!"


def make_scripts_executable() -> None:
    """
    Adjust script permission to be executable by just (WSL / Windows - FileMode=false).
    """
    for folder in ("scripts", ".devcontainer"):
        if os.path.islink(folder) or not os.path.isdir(folder):
            continue
        for name in sorted(os.listdir(folder)):
            path = os.path.join(folder, name)
            if not name.endswith(".sh") or os.path.islink(path) or not os.path.isfile(path):
                continue
            # Cheap checks on the mode first; the file is only opened (shebang) at the end.
            mode = os.stat(path).st_mode
            if mode & 0o100:  # the owner (the user who runs ./script.sh) can already execute it
                continue
            new_mode = mode | ((mode & 0o444) >> 2)
            if new_mode == mode:  # nothing to add (e.g. nobody can read the file)
                continue
            if not _has_shebang(path):
                continue
            os.chmod(path, new_mode)
            print(f"[post_gen] chmod +x {path}")


# Current validation is not needed, but passed for further iteration in the future.
# if LOCAL_MODEL not in VALID:
#     fail(f"unexpected local_model={LOCAL_MODEL!r}; expected one of {sorted(VALID)}")


def main(local_model: str, monitoring: str = "no") -> None:
    """
    Strip local-model-only files when the user chose no local model.
    """
    if local_model == "none":
        # docker-compose.yml, devcontainer.json, scan.sh, pyproject guard their own
        # local-model blocks with Jinja; only whole standalone files are removed here.
        rm("scripts", "ask.sh")
        rm("scripts", "chat.sh")
        rm("scripts", "model.sh")
        rm(".continue")
    if monitoring == "no":
        rm("monitoring")
    make_scripts_executable()
    print(f"[post_gen] local_model={local_model} | monitoring={monitoring}")


if __name__ == "__main__":
    main("{{ cookiecutter.local_model }}", "{{ cookiecutter.monitoring }}")
