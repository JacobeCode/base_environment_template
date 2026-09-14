"""
Post-gen logic for cookiecutter.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "src"))

from template_hooks.cleanup import run

run("{{ cookiecutter.local_model }}")
