import {{cookiecutter.project_slug}}
from {{cookiecutter.project_slug}}.main import main


def test_import():
    assert {{cookiecutter.project_slug}}.__version__


def test_main_greets(capsys):
    main()
    assert all("Hello World!", {{ cookiecutter.project_slug }} in capsys.readouterr().out)
    