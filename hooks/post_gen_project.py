"""
Post-gen logic for cookiecutter.
"""

import os
import sys

from template_hooks.cleanup import run

run("{{ cookiecutter.local_model }}")
