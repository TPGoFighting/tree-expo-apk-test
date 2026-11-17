#!/usr/bin/env python3
"""Find the "Wait" button in an Android ANR dialog from a uiautomator dump.

Reads the UI hierarchy XML (default /tmp/ui.xml), prints the center
coordinates of the first node whose text is "Wait" (case-insensitive),
and exits 0. Exits 1 if no such node (or no bounds) is found.

Used by run-shots.sh to dismiss "System UI isn't responding" dialogs
without hardcoding button coordinates.
"""
import re
import sys

path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/ui.xml"
try:
    xml = open(path, encoding="utf-8", errors="ignore").read()
except OSError:
    sys.exit(1)

for m in re.finditer(r"<node\b[^>]*>", xml):
    node = m.group(0)
    tm = re.search(r'text="([^"]*)"', node)
    if not tm:
        continue
    if tm.group(1).strip().lower() != "wait":
        continue
    bm = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', node)
    if not bm:
        continue
    x1, y1, x2, y2 = map(int, bm.groups())
    print((x1 + x2) // 2, (y1 + y2) // 2)
    sys.exit(0)

sys.exit(1)
