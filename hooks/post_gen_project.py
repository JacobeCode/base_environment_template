"""
Post-gen logic for cookiecutter.
"""

import os
import sys

# Add src to path so template_hooks can be imported
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from template_hooks.cleanup import run

run("{{ cookiecutter.local_model }}")
