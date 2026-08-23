#!/usr/bin/env python3
from __future__ import annotations
import ast, sys
from pathlib import Path

def main() -> int:
    errors = []
    for manifest_path in sorted(Path("addons").glob("*/__manifest__.py")):
        module = manifest_path.parent.name
        try:
            manifest = ast.literal_eval(manifest_path.read_text(encoding="utf-8"))
        except Exception as exc:
            errors.append(f"{module}: invalid __manifest__.py: {exc}")
            continue
        if not isinstance(manifest, dict):
            errors.append(f"{module}: manifest must evaluate to a dict")
            continue
        if not manifest.get("name"):
            errors.append(f"{module}: manifest requires a non-empty 'name'")
        depends = manifest.get("depends", [])
        if not isinstance(depends, list) or not all(isinstance(x, str) for x in depends):
            errors.append(f"{module}: 'depends' must be a list of module names")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("Addon validation passed.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
