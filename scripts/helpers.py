#!/usr/bin/env python3
"""The bits of purrspace that are easier in Python than in shell.

Usage: python3 helpers.py <command> [args]
  papirus-folders <papirus_dir>   swap the blue folders for Mocha mauve ones
  papirus-panel   <theme_dir>...  drop the top bar icons from the theme
  app-folders                     create the app grid folders
  favorites                       pin the dock favorites
  vscode <settings.json> <snippet.json>  merge the purrspace keys into settings
  slack-hide-menu <root-state.json>      hide Slack's menu bar
  obsidian <vault_dir>                   turn on the Catppuccin theme in a vault
"""
import ast
import json
import os
import re
import subprocess
import sys


def gsettings_get(schema, key):
    out = subprocess.check_output(["gsettings", "get", schema, key]).decode().strip()
    out = re.sub(r"^@as ", "", out)
    return ast.literal_eval(out)


def gsettings_set(schema, key, value):
    subprocess.run(["gsettings", "set", schema, key, str(value)], check=True)


def papirus_folders(base):
    """Point the folder-blue*.svg links to the cat-mocha-mauve versions.

    Same result as the official papirus-folders script, without running
    downloaded code.
    """
    swapped = missing = 0
    for size in os.listdir(base):
        d = os.path.join(base, size, "places")
        if not os.path.isdir(d):
            continue
        for f in os.listdir(d):
            p = os.path.join(d, f)
            if not os.path.islink(p):
                continue
            m = re.match(r"^(folder|user)-blue(.*\.svg)$", os.readlink(p))
            if not m:
                continue
            new = f"{m.group(1)}-cat-mocha-mauve{m.group(2)}"
            if os.path.exists(os.path.join(d, new)):
                os.remove(p)
                os.symlink(new, p)
                swapped += 1
            else:
                missing += 1
    print(f"folders swapped: {swapped} (no Catppuccin version, staying blue: {missing})")


def papirus_panel(*themes):
    """Drop the panel and symbolic/status dirs from index.theme.

    The top bar (wifi, bluetooth, sound, battery, tray) goes back to the
    stock GNOME icons and everything else stays Papirus.
    """
    for t in themes:
        p = os.path.join(t, "index.theme")
        out = []
        for line in open(p).read().split("\n"):
            m = re.match(r"^(Directories|ScaledDirectories)=(.*)$", line)
            if m:
                ds = [d for d in m.group(2).split(",")
                      if d and not re.search(r"/(panel|symbolic/status)$", d)]
                line = f"{m.group(1)}={','.join(ds)}"
            out.append(line)
        open(p, "w").write("\n".join(out))
        print("stock top bar icons:", t)


# Folder names stay in Portuguese: that is the language of the desktop.
FOLDERS = {
    "IA": ("Inteligência Artificial", [
        "com.anthropic.Claude.desktop", "chatgpt.desktop", "grok-bot.desktop",
        "ai.opencode.desktop.desktop", "openbot.desktop", "t3code.desktop",
        "venice-ai.desktop", "venice-code.desktop", "agentes.chat.desktop"]),
    "Dev": ("Desenvolvimento", [
        "com.visualstudio.code.desktop", "org.wezfurlong.wezterm.desktop",
        "org.gnome.Terminal.desktop", "bruno.desktop", "dbeaver-ce.desktop",
        "pgadmin4.desktop", "herdr-app.desktop", "org.remmina.Remmina.desktop"]),
    "Internet": ("Internet e Conversas", [
        "com.google.Chrome.desktop", "brave-browser.desktop", "com.slack.Slack.desktop",
        "org.telegram.desktop.desktop", "us.zoom.Zoom.desktop",
        "org.gnome.Evolution.desktop", "webapp-manager.desktop"]),
    "Escritorio": ("Escritório e Estudos", [
        "libreoffice-startcenter.desktop", "libreoffice-writer.desktop",
        "libreoffice-calc.desktop", "libreoffice-impress.desktop",
        "libreoffice-draw.desktop", "md.obsidian.Obsidian.desktop", "granola.desktop",
        "com.github.xournalpp.xournalpp.desktop", "org.gnome.Calendar.desktop",
        "org.gnome.Contacts.desktop", "org.gnome.Evince.desktop", "simple-scan.desktop",
        "painel-estudos.desktop"]),
    "Midia": ("Mídia", [
        "com.spotify.Client.desktop", "org.gnome.Rhythmbox3.desktop",
        "org.gnome.Totem.desktop", "org.gnome.eog.desktop", "org.gnome.Loupe.desktop",
        "org.gnome.Snapshot.desktop", "org.gnome.SoundRecorder.desktop",
        "simplescreenrecorder.desktop", "brasero.desktop"]),
    "Jogos": ("Jogos", ["org.vinegarhq.Sober.desktop", "org.vinegarhq.Vinegar.desktop"]),
    "Sistema": ("Sistema e Ajustes", [
        "org.gnome.Settings.desktop", "org.gnome.tweaks.desktop", "zorin-appearance.desktop",
        "zorin-connect.desktop", "com.mattjakeman.ExtensionManager.desktop",
        "org.gnome.Software.desktop", "software-properties-gtk.desktop",
        "update-manager.desktop", "com.zorin.desktop.upgrader.desktop",
        "gnome-session-properties.desktop", "gnome-language-selector.desktop",
        "gufw.desktop", "nm-connection-editor.desktop", "alacarte.desktop",
        "install-zorin-windows-app-support.desktop", "gparted.desktop",
        "org.gnome.PowerStats.desktop", "org.freedesktop.MalcontentControl.desktop",
        "org.gnome.SystemMonitor.desktop", "org.gnome.DiskUtility.desktop",
        "org.gnome.baobab.desktop", "org.gnome.Logs.desktop", "org.gnome.DejaDup.desktop",
        "org.gnome.seahorse.Application.desktop"]),
    "Utilities": (None, [
        "org.gnome.Calculator.desktop", "org.gnome.Characters.desktop",
        "org.gnome.clocks.desktop", "org.gnome.Weather.desktop",
        "org.gnome.FileRoller.desktop", "org.gnome.font-viewer.desktop",
        "org.gnome.TextEditor.desktop", "anomaly.hex.desktop", "yelp.desktop"]),
}


def app_folders():
    """App grid folders. GNOME simply skips apps that aren't installed."""
    for key, (name, apps) in FOLDERS.items():
        sch = f"org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/{key}/"
        if name:
            gsettings_set(sch, "name", name)
            gsettings_set(sch, "translate", "false")
        gsettings_set(sch, "apps", apps)
        gsettings_set(sch, "categories", [])
    gsettings_set("org.gnome.desktop.app-folders", "folder-children", list(FOLDERS))
    subprocess.run(["gsettings", "reset", "org.gnome.shell", "app-picker-layout"], check=True)
    print("app folders:", ", ".join(FOLDERS))


def favorites():
    fav = ["com.google.Chrome.desktop", "com.visualstudio.code.desktop",
           "com.slack.Slack.desktop", "org.wezfurlong.wezterm.desktop",
           "org.gnome.Nautilus.desktop", "agentes.chat.desktop"]
    gsettings_set("org.gnome.shell", "favorite-apps", fav)
    print("favorites:", fav)


def _jsonc(text):
    text = re.sub(r"(?m)^\s*//.*$", "", text)
    text = re.sub(r",\s*([}\]])", r"\1", text)
    return json.loads(text or "{}")


def vscode(settings, snippet):
    current = _jsonc(open(settings).read()) if os.path.exists(settings) else {}
    current.update(json.load(open(snippet)))
    os.makedirs(os.path.dirname(settings), exist_ok=True)
    json.dump(current, open(settings, "w"), indent=4, ensure_ascii=False)
    print("VS Code configured:", settings)


def slack_hide_menu(path):
    d = json.load(open(path))
    n = 0

    def walk(o):
        nonlocal n
        if isinstance(o, dict):
            for k in o:
                if k == "autoHideMenuBar":
                    o[k] = True
                    n += 1
                else:
                    walk(o[k])
        elif isinstance(o, list):
            for v in o:
                walk(v)

    walk(d)
    json.dump(d, open(path, "w"))
    print(f"Slack: menu bar hidden ({n} keys)")


def obsidian(vault):
    p = os.path.join(vault, ".obsidian", "appearance.json")
    d = json.load(open(p)) if os.path.exists(p) else {}
    d.update({"cssTheme": "Catppuccin", "theme": "obsidian"})
    json.dump(d, open(p, "w"), indent=2)
    print("Obsidian: Catppuccin theme on in", vault)


if __name__ == "__main__":
    cmds = {
        "papirus-folders": papirus_folders, "papirus-panel": papirus_panel,
        "app-folders": app_folders, "favorites": favorites, "vscode": vscode,
        "slack-hide-menu": slack_hide_menu, "obsidian": obsidian,
    }
    if len(sys.argv) < 2 or sys.argv[1] not in cmds:
        print(__doc__)
        sys.exit(1)
    cmds[sys.argv[1]](*sys.argv[2:])
