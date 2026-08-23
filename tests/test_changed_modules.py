import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "changed_modules.py"


def git(repo, *args):
    subprocess.run(["git", *args], cwd=repo, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def commit_all(repo, message):
    git(repo, "add", ".")
    git(repo, "commit", "-m", message)
    return subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo, text=True).strip()


def run_script(repo, base, head):
    p = subprocess.run([sys.executable, str(SCRIPT), base, head], cwd=repo, check=True, capture_output=True, text=True)
    rows = dict(line.split("=", 1) for line in p.stdout.strip().splitlines())
    return rows


def test_detects_new_and_updated_modules(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    git(repo, "init")
    git(repo, "config", "user.email", "test@example.com")
    git(repo, "config", "user.name", "Test")

    a = repo / "addons" / "existing"
    a.mkdir(parents=True)
    (a / "__manifest__.py").write_text("{'name':'Existing'}")
    (a / "models.py").write_text("x=1")
    base = commit_all(repo, "base")

    (a / "models.py").write_text("x=2")
    b = repo / "addons" / "new_module"
    b.mkdir()
    (b / "__manifest__.py").write_text("{'name':'New'}")
    head = commit_all(repo, "change")

    rows = run_script(repo, base, head)
    assert rows["INSTALL_MODULES"] == "new_module"
    assert rows["UPDATE_MODULES"] == "existing"


def test_ignores_non_module_files(tmp_path):
    repo = tmp_path / "repo"
    repo.mkdir()
    git(repo, "init")
    git(repo, "config", "user.email", "test@example.com")
    git(repo, "config", "user.name", "Test")
    (repo / "README.md").write_text("a")
    base = commit_all(repo, "base")
    (repo / "README.md").write_text("b")
    head = commit_all(repo, "docs")
    rows = run_script(repo, base, head)
    assert rows["INSTALL_MODULES"] == ""
    assert rows["UPDATE_MODULES"] == ""
