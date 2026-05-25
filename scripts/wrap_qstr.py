#!/usr/bin/env python3
"""
wrap_qstr.py — Wraps hardcoded QML string literals with qsTr().

Usage (from project root):
    python scripts/wrap_qstr.py --dry-run   # preview
    python scripts/wrap_qstr.py             # apply changes

What it does:
    text: "Save"             →  text: qsTr("Save")
    title: "Node Settings"  →  title: qsTr("Node Settings")

Skips:
    - Strings already wrapped in qsTr(...)
    - URLs, hex colors, version strings, identifiers, etc.
    - Strings in comment lines (// ...)
    - console.log / qDebug lines
"""
import re
import sys
import os
from pathlib import Path

DRY_RUN = "--dry-run" in sys.argv or "-n" in sys.argv

# ── Regex: match property: "literal" (not already qsTr) ─────────────────────
PROP_NAMES = (
    "text|title|label|placeholder|placeholderText|tooltip|description"
    "|emptyText|headerText|footerText|buttonText|confirmText|hint|statusText"
)
PATTERN = re.compile(
    r'(?P<indent>[ \t]*)(?P<prop>' + PROP_NAMES + r'):\s+'
    r'(?!qsTr\()(?!i18n\()(?!Qt\.)'
    r'"(?P<val>[^"\\\n]+)"'
)

# ── Values that must NOT be wrapped ─────────────────────────────────────────
SKIP_RE = re.compile(
    r'^$'                                   # empty
    r'|^https?://'                          # URLs
    r'|^qrc:/'                              # Qt resource paths
    r'|^v\d+\.\d+'                          # version strings v1.0.0
    r'|^\d+(\.\d+)?$'                       # pure numbers
    r'|^#[0-9a-fA-F]{3,8}$'               # hex colours
    r'|^[a-z][a-zA-Z0-9_]*$'              # camelCase / lowercase identifiers
    r'|^\w+\.\w+(\.\w+)*$'                # dotted identifiers
    r'|^(true|false|null|undefined)$'      # JS primitives
    r'|^[a-z]+(-[a-z]+)+$'               # kebab-case (bezier, bottom-left …)
    r'|^(en|pt_BR|es|fr|de)$'            # language codes
    r'|^rgb\('                             # CSS rgb()
)

# Lines containing these patterns are skipped entirely
LINE_SKIP_RE = re.compile(r'(//|/\*|console\.(log|warn|error)|qDebug)')


def should_skip_value(val: str) -> bool:
    return bool(SKIP_RE.match(val))


def process_file(path: Path) -> int:
    """Returns number of replacements made."""
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines(keepends=True)
    new_lines = []
    count = 0

    for line in lines:
        # Skip comment / debug lines
        stripped = line.lstrip()
        if LINE_SKIP_RE.search(stripped):
            new_lines.append(line)
            continue

        def replace_match(m: re.Match) -> str:
            val = m.group("val")
            if should_skip_value(val):
                return m.group(0)
            nonlocal count
            count += 1
            return f'{m.group("indent")}{m.group("prop")}: qsTr("{val}")'

        new_line = PATTERN.sub(replace_match, line)
        new_lines.append(new_line)

    if count > 0 and not DRY_RUN:
        path.write_text("".join(new_lines), encoding="utf-8")

    return count


def main():
    script_dir = Path(__file__).parent
    qml_root = (script_dir / ".." / "valkyrieGUI" / "resources" / "qml").resolve()

    if not qml_root.exists():
        print(f"ERROR: QML root not found: {qml_root}", file=sys.stderr)
        sys.exit(1)

    qml_files = sorted(qml_root.rglob("*.qml"))
    total_files = 0
    total_wraps = 0

    for f in qml_files:
        n = process_file(f)
        if n > 0:
            total_files += 1
            total_wraps += n
            rel = f.relative_to(qml_root)
            if DRY_RUN:
                print(f"[DryRun] {rel} — {n} string(s) would be wrapped")
            else:
                print(f"Updated: {rel}")

    print()
    if DRY_RUN:
        print(f"DRY RUN: {total_wraps} string(s) in {total_files} file(s) would be wrapped.")
        print("Run without --dry-run to apply.")
    else:
        print(f"Done: {total_wraps} string(s) wrapped in {total_files} file(s).")
        print("Review: git diff valkyrieGUI/resources/qml/")
        print("Then:   cmake --build build --target update_translations")


if __name__ == "__main__":
    main()
