#!/usr/bin/env python3
"""Draws the README images in docs/assets/ from the theme itself.

No screenshots: everything is drawn with the Mocha palette, the repo's
fastfetch cat, the Catppuccin Papirus folders and the JetBrains Mono font.

    python3 scripts/make-readme-assets.py

Needs Pillow, PyGObject (GdkPixbuf) and the icons installed by install.sh.
"""
import math
import os
import random
import re

import gi

gi.require_version("GdkPixbuf", "2.0")
from gi.repository import GdkPixbuf  # noqa: E402
from PIL import Image, ImageDraw, ImageFilter, ImageFont  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "assets")
os.makedirs(OUT, exist_ok=True)

M = dict(
    crust="#11111b", mantle="#181825", base="#1e1e2e", s0="#313244", s1="#45475a",
    s2="#585b70", ov0="#6c7086", sub="#a6adc8", text="#cdd6f4", lavender="#b4befe",
    blue="#89b4fa", sapphire="#74c7ec", sky="#89dceb", teal="#94e2d5", green="#a6e3a1",
    yellow="#f9e2af", peach="#fab387", maroon="#eba0ac", red="#f38ba8", mauve="#cba6f7",
    pink="#f5c2e7", flamingo="#f2cdcd", rosewater="#f5e0dc",
)


def rgb(h, a=255):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (a,)


def font(size, bold=True):
    d = os.path.expanduser("~/.local/share/fonts/JetBrainsMonoNerd")
    name = "JetBrainsMonoNerdFont-Bold.ttf" if bold else "JetBrainsMonoNerdFont-Regular.ttf"
    return ImageFont.truetype(os.path.join(d, name), size)


def icon(path, size):
    pb = GdkPixbuf.Pixbuf.new_from_file_at_size(path, size, size)
    tmp = os.path.join(OUT, ".tmp.png")
    pb.savev(tmp, "png", [], [])
    im = Image.open(tmp).convert("RGBA")
    os.remove(tmp)
    return im


ICONS = os.path.expanduser("~/.local/share/icons")
PLACES = os.path.join(ICONS, "Papirus", "64x64", "places")
APPS = os.path.join(ICONS, "Papirus-Dark", "64x64", "apps")


def folder(kind):
    name = "folder-cat-mocha-mauve.svg" if kind == "" else f"folder-cat-mocha-mauve-{kind}.svg"
    return os.path.join(PLACES, name)


def traffic_lights(d, right, cy, r=9, gap=26):
    """minimize, maximize, close — on the right, like the real thing."""
    for i, col in enumerate(["yellow", "green", "red"]):
        cx = right - (2 - i) * gap
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=rgb(M[col]))


def shadow(img, box, radius, blur=28, alpha=150):
    sh = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(box, radius=radius, fill=(0, 0, 0, alpha))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    img.alpha_composite(sh)


# ---------------------------------------------------------------- the cat

def cat_lines():
    """fastfetch's cat.txt uses $1..$5 for colors."""
    colors = {"1": M["sky"], "2": M["red"], "3": M["yellow"], "4": M["blue"], "5": M["green"]}
    raw = open(os.path.join(ROOT, "files", "fastfetch", "cat.txt")).read().rstrip("\n").split("\n")
    out = []
    for line in raw:
        cur, segs = M["text"], []
        for part in re.split(r"(\$\d)", line):
            if re.fullmatch(r"\$\d", part):
                cur = colors.get(part[1], M["text"])
            elif part:
                segs.append((part, cur))
        out.append(segs)
    return out


def draw_cat(d, x, y, size):
    f = font(size)
    cw = f.getlength("M")
    for i, segs in enumerate(cat_lines()):
        cx = x
        for txt, col in segs:
            d.text((cx, y + i * size * 1.02), txt, fill=rgb(col), font=f)
            cx += cw * len(txt)


def mascot():
    """The purrspace cat: a kitten purring in a cup (cat + cappuccino = Catppuccin)."""
    m = M
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="320" height="364" viewBox="0 -44 320 364">
  <!-- steam, purring -->
  <path d="M128 52 q-12 -14 0 -28 q12 -14 0 -28" transform="translate(0 -8)" fill="none" stroke="{m['pink']}" stroke-width="7" stroke-linecap="round" opacity=".9"/>
  <path d="M192 52 q-12 -14 0 -28 q12 -14 0 -28" transform="translate(0 0)" fill="none" stroke="{m['mauve']}" stroke-width="7" stroke-linecap="round" opacity=".9"/>
  <!-- saucer -->
  <ellipse cx="160" cy="296" rx="128" ry="16" fill="{m['s1']}"/>
  <ellipse cx="160" cy="290" rx="128" ry="16" fill="{m['s2']}"/>
  <ellipse cx="160" cy="288" rx="78" ry="8" fill="{m['s1']}"/>
  <!-- handle -->
  <circle cx="258" cy="212" r="27" fill="none" stroke="{m['rosewater']}" stroke-width="15"/>
  <!-- inside of the cup -->
  <ellipse cx="160" cy="160" rx="100" ry="22" fill="{m['s0']}"/>
  <!-- the cat -->
  <g transform="translate(0 -16)">
  <path d="M96 118 L100 54 L146 92 Z" fill="{m['mauve']}" stroke="{m['mauve']}" stroke-width="10" stroke-linejoin="round"/>
  <path d="M224 118 L220 54 L174 92 Z" fill="{m['mauve']}" stroke="{m['mauve']}" stroke-width="10" stroke-linejoin="round"/>
  <path d="M108 100 L110 72 L130 90 Z" fill="{m['pink']}" stroke="{m['pink']}" stroke-width="6" stroke-linejoin="round"/>
  <path d="M212 100 L210 72 L190 90 Z" fill="{m['pink']}" stroke="{m['pink']}" stroke-width="6" stroke-linejoin="round"/>
  <ellipse cx="160" cy="140" rx="74" ry="58" fill="{m['mauve']}"/>
  <path d="M148 88 q12 -8 24 0" fill="none" stroke="{m['lavender']}" stroke-opacity=".6" stroke-width="5" stroke-linecap="round"/>
  <ellipse cx="116" cy="152" rx="14" ry="9" fill="{m['pink']}" opacity=".9"/>
  <ellipse cx="204" cy="152" rx="14" ry="9" fill="{m['pink']}" opacity=".9"/>
  <path d="M112 134 q13 12 26 0" fill="none" stroke="{m['base']}" stroke-width="6" stroke-linecap="round"/>
  <path d="M182 134 q13 12 26 0" fill="none" stroke="{m['base']}" stroke-width="6" stroke-linecap="round"/>
  <path d="M153 146 h14 l-7 7 z" fill="{m['red']}" stroke="{m['red']}" stroke-width="4" stroke-linejoin="round"/>
  <path d="M147 157 q6.5 8 13 0 q6.5 8 13 0" fill="none" stroke="{m['base']}" stroke-width="4" stroke-linecap="round"/>
  <path d="M88 144 l-28 -5 M88 154 l-28 5 M232 144 l28 -5 M232 154 l28 5" stroke="{m['lavender']}" stroke-width="3" stroke-linecap="round"/>
  </g>
  <!-- cup -->
  <path d="M60 168 H260 V196 C260 252 216 282 160 282 C104 282 60 252 60 196 Z" fill="{m['rosewater']}"/>
  <ellipse cx="160" cy="168" rx="100" ry="10" fill="{m['flamingo']}"/>
  <path d="M60 168 H260" stroke="{m['flamingo']}" stroke-width="2"/>
  <path d="M74 200 C78 240 108 264 140 270" fill="none" stroke="#ffffff" stroke-opacity=".45" stroke-width="8" stroke-linecap="round"/>
  <circle cx="134" cy="222" r="9" fill="{m['yellow']}"/>
  <circle cx="160" cy="222" r="9" fill="{m['green']}"/>
  <circle cx="186" cy="222" r="9" fill="{m['red']}"/>
  <!-- paws on the rim -->
  <ellipse cx="124" cy="168" rx="19" ry="12" fill="{m['mauve']}"/>
  <ellipse cx="196" cy="168" rx="19" ry="12" fill="{m['mauve']}"/>
  <path d="M118 164 v7 M126 164 v7 M190 164 v7 M198 164 v7" stroke="{m['base']}" stroke-opacity=".35" stroke-width="2.5" stroke-linecap="round"/>
</svg>"""
    open(os.path.join(OUT, "purrcup.svg"), "w").write(svg)
    old = os.path.join(OUT, "cat.svg")
    if os.path.exists(old):
        os.remove(old)


# ---------------------------------------------------------------- hero

def hero():
    W, H = 1600, 900
    img = Image.new("RGBA", (W, H), rgb(M["base"]))
    d = ImageDraw.Draw(img)
    # night sky: mantle at the top, a mauve-pink glow near the horizon
    for y in range(H):
        t = y / H
        a = rgb(M["crust"]); b = rgb("#3b2f55"); c = rgb("#6a4a72")
        if t < 0.6:
            k = t / 0.6; col = tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))
        else:
            k = (t - 0.6) / 0.4; col = tuple(int(b[i] + (c[i] - b[i]) * k) for i in range(3))
        d.line([(0, y), (W, y)], fill=col + (255,))
    random.seed(7)
    for _ in range(220):
        x, y = random.randint(0, W), random.randint(40, int(H * 0.75))
        r = random.choice([1, 1, 1, 2])
        d.ellipse([x, y, x + r, y + r], fill=rgb(random.choice([M["text"], M["lavender"], M["pink"]]), random.randint(90, 230)))
    # soft hills
    for k, col in enumerate(["#2a2140", "#221b35", "#1a1528"]):
        pts = [(0, H)]
        for x in range(0, W + 40, 40):
            pts.append((x, H - 150 + k * 45 - 50 * math.sin(x / (230 + k * 60) + k)))
        pts.append((W, H))
        d.polygon(pts, fill=rgb(col))

    # top bar
    d.rectangle([0, 0, W, 38], fill=rgb(M["s0"], 235))
    d.rounded_rectangle([12, 8, 66, 30], radius=11, fill=rgb(M["base"], 210))
    d.rounded_rectangle([20, 15, 44, 23], radius=4, fill=rgb(M["text"]))
    d.ellipse([50, 15, 58, 23], fill=rgb(M["sub"]))
    clock = "Fri Nov 20  09:32"
    fc = font(17)
    cw = fc.getlength(clock)
    d.rounded_rectangle([W / 2 - cw / 2 - 14, 6, W / 2 + cw / 2 + 14, 32], radius=11, fill=rgb(M["base"], 210))
    d.text((W / 2 - cw / 2, 9), clock, fill=rgb("#e9f2fa"), font=fc)
    d.rounded_rectangle([W - 150, 6, W - 12, 32], radius=11, fill=rgb(M["base"], 210))
    for i in range(4):
        d.ellipse([W - 136 + i * 30, 13, W - 124 + i * 30, 25], fill=rgb(M["text"]))

    # Files window
    fx, fy, fw, fh = 110, 90, 860, 540
    shadow(img, [fx, fy + 10, fx + fw, fy + fh + 10], 18)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([fx, fy, fx + fw, fy + fh], radius=16, fill=rgb(M["base"]))
    d.rounded_rectangle([fx, fy, fx + 230, fy + fh], radius=16, fill=rgb(M["mantle"]))
    d.rectangle([fx + 200, fy, fx + 230, fy + fh], fill=rgb(M["mantle"]))
    d.text((fx + 22, fy + 18), "Files", fill=rgb(M["text"]), font=font(18))
    side = [("", "Home", "home"), ("documents", "Documents", None), ("download", "Downloads", None),
            ("music", "Music", None), ("pictures", "Pictures", None), ("videos", "Videos", None)]
    for i, (k, label, _) in enumerate(side):
        y = fy + 66 + i * 44
        if i == 0:
            d.rounded_rectangle([fx + 12, y - 8, fx + 218, y + 30], radius=10, fill=rgb("#3d3354"))
        ic = icon(folder(k), 24)
        img.alpha_composite(ic, (fx + 24, y - 2))
        d.text((fx + 58, y), label, fill=rgb(M["mauve"] if i == 0 else M["text"]), font=font(15, bold=i == 0))
    d.rounded_rectangle([fx + 250, fy + 14, fx + fw - 120, fy + 46], radius=10, fill=rgb(M["s0"]))
    d.text((fx + 268, fy + 20), "~/  Home", fill=rgb(M["text"]), font=font(15))
    traffic_lights(d, fx + fw - 26, fy + 30)
    grid = [("code", "Projects"), ("documents", "Documents"), ("download", "Downloads"),
            ("music", "Music"), ("pictures", "Pictures"), ("videos", "Videos"),
            ("github", "dotfiles"), ("games", "Games")]
    for i, (k, label) in enumerate(grid):
        gx = fx + 270 + (i % 4) * 142
        gy = fy + 90 + (i // 4) * 170
        ic = icon(folder(k), 96)
        img.alpha_composite(ic, (gx, gy))
        tw = font(15, bold=False).getlength(label)
        d.text((gx + 48 - tw / 2, gy + 104), label, fill=rgb(M["text"]), font=font(15, bold=False))

    # terminal window
    tx, ty, tw_, th = 760, 330, 760, 450
    shadow(img, [tx, ty + 10, tx + tw_, ty + th + 10], 18)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([tx, ty, tx + tw_, ty + th], radius=16, fill=rgb(M["base"]))
    d.rounded_rectangle([tx, ty, tx + tw_, ty + 44], radius=16, fill=rgb(M["mantle"]))
    d.rectangle([tx, ty + 28, tx + tw_, ty + 44], fill=rgb(M["mantle"]))
    d.text((tx + tw_ / 2 - 40, ty + 12), "WezTerm", fill=rgb(M["sub"]), font=font(15))
    traffic_lights(d, tx + tw_ - 26, ty + 22)
    # tmux bar
    d.rectangle([tx, ty + 44, tx + tw_, ty + 70], fill=rgb(M["s0"]))
    d.rectangle([tx, ty + 44, tx + 64, ty + 70], fill=rgb(M["peach"]))
    d.text((tx + 10, ty + 47), "main", fill=rgb(M["base"]), font=font(15))
    d.rectangle([tx + 64, ty + 44, tx + 158, ty + 70], fill=rgb(M["yellow"]))
    d.text((tx + 72, ty + 47), "1:purr*", fill=rgb(M["base"]), font=font(15))
    d.text((tx + tw_ - 82, ty + 47), "09:32", fill=rgb(M["pink"]), font=font(15))
    # fastfetch
    draw_cat(d, tx + 26, ty + 88, 7.4)
    info = [("OS", "Zorin OS 18.1", "yellow"), ("DE", "GNOME 46", "blue"),
            ("Theme", "Catppuccin Mocha", "mauve"), ("Icons", "Papirus + mauve folders", "pink"),
            ("Cursor", "Bibata Modern Ice", "sky"), ("Font", "JetBrains Mono", "green"),
            ("Shell", "zsh + tmux", "peach")]
    for i, (k, v, col) in enumerate(info):
        y = ty + 112 + i * 30
        d.text((tx + 360, y), f"{k:<7}", fill=rgb(M[col]), font=font(17))
        d.text((tx + 450, y), v, fill=rgb(M["text"]), font=font(17, bold=False))
    for i, col in enumerate(["s1", "red", "green", "yellow", "blue", "pink", "teal", "text"]):
        d.rounded_rectangle([tx + 360 + i * 38, ty + 340, tx + 390 + i * 38, ty + 360], radius=5, fill=rgb(M[col]))
    d.text((tx + 22, ty + 400), "❯", fill=rgb(M["mauve"]), font=font(19))
    d.rectangle([tx + 46, ty + 402, tx + 58, ty + 424], fill=rgb(M["pink"]))

    # dock
    dock = [icon(os.path.join(APPS, "org.gnome.Nautilus.svg"), 56),
            icon(os.path.join(APPS, "org.wezfurlong.wezterm.svg"), 56),
            icon(os.path.join(ROOT, "files", "icons", "t3code-catppuccin.svg"), 56),
            icon(os.path.join(APPS, "org.gnome.Settings.svg"), 56),
            icon(os.path.join(APPS, "org.gnome.TextEditor.svg"), 56)]
    dw = len(dock) * 72 + 24
    dx, dy = W / 2 - dw / 2, H - 98
    shadow(img, [dx, dy + 6, dx + dw, dy + 82], 22, blur=16, alpha=120)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([dx, dy, dx + dw, dy + 82], radius=22, fill=rgb(M["base"], 225))
    for i, ic in enumerate(dock):
        img.alpha_composite(ic, (int(dx + 20 + i * 72), int(dy + 13)))
    img.convert("RGB").save(os.path.join(OUT, "hero.png"), optimize=True)


# ---------------------------------------------------------------- close-ups

def buttons():
    """Before and after of the window buttons."""
    W, H = 820, 200
    img = Image.new("RGBA", (W, H), rgb(M["crust"]))
    d = ImageDraw.Draw(img)
    for k, (title, x) in enumerate([("stock", 30), ("purrspace", 430)]):
        d.rounded_rectangle([x, 50, x + 360, 140], radius=16, fill=rgb(M["base"]))
        d.rounded_rectangle([x, 50, x + 360, 100], radius=16, fill=rgb(M["mantle"]))
        d.rectangle([x, 84, x + 360, 100], fill=rgb(M["mantle"]))
        d.text((x + 20, 64), "Files", fill=rgb(M["text"]), font=font(17))
        if k == 0:
            for i, g in enumerate(["–", "□", "×"]):
                cx = x + 270 + i * 34
                d.ellipse([cx - 13, 62, cx + 13, 88], fill=rgb(M["s0"]))
                d.text((cx - 6, 63), g, fill=rgb(M["text"]), font=font(17))
        else:
            traffic_lights(d, x + 330, 75, r=10, gap=30)
        d.text((x, 154), title, fill=rgb(M["sub"] if k == 0 else M["mauve"]), font=font(16))
    d.text((396, 78), "→", fill=rgb(M["pink"]), font=font(30))
    img.convert("RGB").save(os.path.join(OUT, "buttons.png"), optimize=True)


def folders():
    kinds = [("", "folder"), ("documents", "documents"), ("download", "downloads"),
             ("music", "music"), ("pictures", "pictures"), ("videos", "videos"),
             ("code", "code"), ("github", "github"), ("games", "games"), ("favorites", "favorites")]
    W, H = 5 * 150 + 40, 2 * 150 + 40
    img = Image.new("RGBA", (W, H), rgb(M["base"]))
    d = ImageDraw.Draw(img)
    for i, (k, label) in enumerate(kinds):
        x, y = 20 + (i % 5) * 150, 20 + (i // 5) * 150
        img.alpha_composite(icon(folder(k), 96), (x + 27, y + 4))
        tw = font(14, bold=False).getlength(label)
        d.text((x + 75 - tw / 2, y + 108), label, fill=rgb(M["sub"]), font=font(14, bold=False))
    img.convert("RGB").save(os.path.join(OUT, "folders.png"), optimize=True)


if __name__ == "__main__":
    mascot()
    hero()
    buttons()
    folders()
    print("assets written to", OUT)
