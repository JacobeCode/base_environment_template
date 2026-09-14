"""
Post-gen logic for cookiecutter.
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from template_hooks.cleanup import run

run("{{ cookiecutter.local_model }}")
