#!/usr/bin/env python3
"""Make T3 Code use the system title bar on Linux, so it gets the traffic lights.

Usage: sudo python3 scripts/t3-traffic-lights.py [path/to/app.asar]
       (default: the T3 Code installed in /opt)

T3 opens its window with titleBarStyle "hidden" + titleBarOverlay, so Electron
draws its own buttons on top. This renames both options in the Linux branch to
names Electron doesn't know, with the same length (titleBarStylX /
titleBarOverlaX). Electron ignores them and uses the system title bar. The size
doesn't change, so app.asar stays valid. Close T3 first; run again after each
T3 update.

Exit: 0 = applied, 10 = already applied,
      20 = snippet not found (T3 changed its code; nothing was touched).
"""
import os
import shutil
import sys

ORIGINAL = b'\treturn {\n\t\ttitleBarStyle: "hidden",\n\t\ttitleBarOverlay: {'
PATCHED = b'\treturn {\n\t\ttitleBarStylX: "hidden",\n\t\ttitleBarOverlaX: {'
assert len(ORIGINAL) == len(PATCHED)

asar = sys.argv[1] if len(sys.argv) > 1 else "/opt/T3 Code (Beta)/resources/app.asar"
data = open(asar, "rb").read()

if data.count(PATCHED) == 1:
    print("already applied:", asar)
    sys.exit(10)
if data.count(ORIGINAL) != 1:
    print("expected snippet not found; T3 changed its code. Nothing was touched:", asar)
    sys.exit(20)

backup = asar + ".before-traffic-lights"
shutil.copy2(asar, backup)
tmp = asar + ".tmp"
with open(tmp, "wb") as f:
    f.write(data.replace(ORIGINAL, PATCHED, 1))
shutil.copystat(asar, tmp)
os.replace(tmp, asar)
print("applied:", asar, "| backup:", backup)
sys.exit(0)
