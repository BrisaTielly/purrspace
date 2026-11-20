#!/usr/bin/env python3
"""Draws files/wallpapers/waves.png, the purrspace wallpaper (1920x1080, Mocha).

    python3 scripts/make-wallpaper.py

Needs Pillow and numpy. Seeded, so it always draws the same picture.
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw

W, H = 1920, 1080
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "files", "wallpapers")
os.makedirs(OUT, exist_ok=True)


def hx(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float)


base, crust = hx("1e1e2e"), hx("11111b")
rng = np.random.default_rng(3)
# the first draft drew two other wallpapers first; skip their noise so the grain matches
rng.normal(0, 1, (H, W)); rng.normal(0, 1, (H, W))


def grain(a, amt=3.0):
    return a + rng.normal(0, amt, a.shape[:2])[..., None]


def save(a, name):
    Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).save(f"{OUT}/{name}.png", optimize=True)
    print("wrote", f"{OUT}/{name}.png")


# soft mauve waves rising from the bottom
img=Image.new('RGB',(W,H)); d=ImageDraw.Draw(img)
for y in range(H):
    k=y/H; c=crust*(1-k)+base*k; d.line([(0,y),(W,y)],fill=tuple(int(v) for v in c))
for i,(col,amp,off,freq) in enumerate([('#2b2a3f',40,640,1/420),('#352f4f',34,730,1/360),('#45385e',28,820,1/300),('#5b4778',22,910,1/260)]):
    pts=[(0,H)]+[(x,off+amp*math.sin(x*freq*2*math.pi/6.28+i*1.3)+12*math.sin(x/97+i)) for x in range(0,W+10,10)]+[(W,H)]
    d.polygon(pts,fill=col)
save(grain(np.array(img,float),2),'waves')

