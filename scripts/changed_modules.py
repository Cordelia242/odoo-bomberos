#!/usr/bin/env python3
from __future__ import annotations
import subprocess, sys
from pathlib import Path

def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], text=True).strip()

def module_names_from_paths(paths: list[str]) -> set[str]:
    modules = set()
    for raw in paths:
        parts = Path(raw).parts
        if len(parts) >= 2 and parts[0] == "addons":
            module = parts[1]
            if (Path("addons") / module / "__manifest__.py").exists():
                modules.add(module)
    return modules

def diff_paths(base: str, head: str, diff_filter: str | None = None) -> list[str]:
    args = ["diff", "--name-only"]
    if diff_filter:
        args.append(f"--diff-filter={diff_filter}")
    args.extend([base, head, "--", "addons"])
    out = git(*args)
    return [x for x in out.splitlines() if x.strip()]

def main() -> int:
    if len(sys.argv) != 3:
        print("usage: changed_modules.py <base-ref> <head-ref>", file=sys.stderr)
        return 2
    base, head = sys.argv[1], sys.argv[2]
    changed = module_names_from_paths(diff_paths(base, head))
    added = diff_paths(base, head, "A")
    new = {
        Path(p).parts[1] for p in added
        if len(Path(p).parts) == 3
        and Path(p).parts[0] == "addons"
        and Path(p).name == "__manifest__.py"
    }
    install = sorted(changed & new)
    update = sorted(changed - set(install))
    print(f"INSTALL_MODULES={','.join(install)}")
    print(f"UPDATE_MODULES={','.join(update)}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
