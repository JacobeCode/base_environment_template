"""Shared fixtures for the template's render/bake tests."""

import traceback

import pytest


def assert_baked_ok(result):
    """
    Fail with a full traceback, not just the exception's class name.
    """
    if result.exception is not None:
        traceback.print_exception(type(result.exception), result.exception, result.exception.__traceback__)
    assert result.exit_code == 0, f"bake failed: {result.exception!r}"
    assert result.exception is None


@pytest.fixture
def baked(cookies):
    """Bake with the given overrides, asserting success, returning the Result.

    Usage: result = baked(local_model="none", gpu_usage="yes")
    No overrides bakes with cookiecutter.json's defaults.
    """

    def _bake(**extra_context):
        result = cookies.bake(extra_context=extra_context)
        assert_baked_ok(result)
        return result

    return _bake
