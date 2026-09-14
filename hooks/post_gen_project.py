"""
Post-gen logic for cookiecutter.
"""

from template_hooks.cleanup import run

run("{{ cookiecutter.local_model }}")
