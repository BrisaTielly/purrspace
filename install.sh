#!/usr/bin/env bash
# purrspace: Catppuccin Mocha for GNOME (made on Zorin OS 18 / GNOME 46 / Wayland).
#
#   ./install.sh                 run every step
#   ./install.sh theme icons     run only the steps you name
#   ./install.sh --list          list the steps
#
# No sudo: everything goes into your home folder. Before touching anything it
# saves a backup to ~/.config/purrspace-backup/<date>/. Safe to run again.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
F="$ROOT/files"
HELP="python3 $ROOT/scripts/helpers.py"
TMP="$(mktemp -d)"
BACKUP="$HOME/.config/purrspace-backup/$(date +%F-%H%M)"
ICONS="$HOME/.local/share/icons"
FAILED=()

trap 'rm -rf "$TMP"' EXIT

ok()   { printf '\e[32m  ✓ %s\e[0m\n' "$*"; }
step() { printf '\e[35m▸ %s\e[0m\n' "$*"; }
warn() { printf '\e[33m  ! %s\e[0m\n' "$*"; }
has()  { command -v "$1" >/dev/null 2>&1; }

fetch() { curl -fsSL --retry 2 -o "$2" "$1"; }

# copy a file into the backup, keeping its path, before overwriting it
keep() {
    [ -e "$1" ] || return 0
    local dest="$BACKUP${1#"$HOME"}"
    mkdir -p "$(dirname "$dest")" && cp -a "$1" "$dest" 2>/dev/null; true
}

# ---------------------------------------------------------------- steps

step_backup() {
    step "Backing up the current setup to $BACKUP"
    mkdir -p "$BACKUP"
    dconf dump /org/gnome/ > "$BACKUP/gnome-dconf.ini" && ok "dconf saved"
}

step_fonts() {
    step "JetBrains Mono Nerd Font"
    if fc-list | grep -qi "JetBrainsMono Nerd Font"; then ok "already there"; return; fi
    local d="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    fetch https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz "$TMP/jb.tar.xz" || return 1
    mkdir -p "$d" && tar -xJf "$TMP/jb.tar.xz" -C "$d" && fc-cache -f >/dev/null && ok "installed"
}

step_cursor() {
    step "Bibata Modern Ice cursor"
    if [ ! -d "$ICONS/Bibata-Modern-Ice" ]; then
        fetch https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata-Modern-Ice.tar.xz "$TMP/bibata.tar.xz" || return 1
        mkdir -p "$ICONS" && tar -xJf "$TMP/bibata.tar.xz" -C "$ICONS" || return 1
    fi
    # GNOME Shell and X11 apps look for cursors in ~/.icons, and the system
    # "default" cursor theme points at Adwaita, so point both at Bibata
    mkdir -p "$HOME/.icons/default"
    ln -sfn "$ICONS/Bibata-Modern-Ice" "$HOME/.icons/Bibata-Modern-Ice"
    printf '[Icon Theme]\nName=Default\nInherits=Bibata-Modern-Ice\n' > "$HOME/.icons/default/index.theme"
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
    gsettings set org.gnome.desktop.interface cursor-size 24
    ok "applied"
}

step_theme() {
    step "Catppuccin theme (windows, top bar, traffic lights)"
    mkdir -p "$HOME/.themes" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    rm -rf "$HOME/.themes/Catppuccin-GnomeTheme"
    cp -r "$F/themes/Catppuccin-GnomeTheme" "$HOME/.themes/"

    # GTK4/libadwaita: base theme (catppuccin.css) + the traffic-light rules on top
    keep "$HOME/.config/gtk-4.0/gtk.css"; keep "$HOME/.config/gtk-3.0/gtk.css"
    cp "$F/themes/Catppuccin-GnomeTheme/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/catppuccin.css"
    rm -rf "$HOME/.config/gtk-4.0/assets"
    cp -r "$F/themes/Catppuccin-GnomeTheme/gtk-4.0/assets" "$HOME/.config/gtk-4.0/"
    cp "$F/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
    cp "$F/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"

    gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-GnomeTheme'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null \
        || warn "User Themes extension not found; the 'extensions' step installs it"
    gsettings set org.gnome.shell.extensions.user-theme name 'Catppuccin-GnomeTheme' 2>/dev/null || true
    ok "theme applied"
    # Files keeps running in the background and won't reread the CSS on its own
    nautilus -q 2>/dev/null || true
}

step_icons() {
    step "Papirus icons with Catppuccin Mocha mauve folders"
    fetch https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/heads/master.tar.gz "$TMP/papirus.tgz" || return 1
    mkdir -p "$TMP/papirus" && tar -xzf "$TMP/papirus.tgz" -C "$TMP/papirus" || return 1
    local src; src="$(ls -d "$TMP"/papirus/*/)"
    for t in Papirus Papirus-Dark; do
        [ -d "$ICONS/$t" ] && mkdir -p "$BACKUP" && mv "$ICONS/$t" "$BACKUP/$t-icons"
        cp -r "$src/$t" "$ICONS/"
    done
    git clone -q --depth 1 https://github.com/catppuccin/papirus-folders "$TMP/pf" || return 1
    cp -r "$TMP"/pf/src/* "$ICONS/Papirus/"
    $HELP papirus-folders "$ICONS/Papirus"
    $HELP papirus-panel "$ICONS/Papirus" "$ICONS/Papirus-Dark"
    for t in Papirus Papirus-Dark; do gtk-update-icon-cache -qf "$ICONS/$t" 2>/dev/null || true; done
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    ok "icons applied"
}

EXTENSIONS=(
    user-theme@gnome-shell-extensions.gcampax.github.com
    blur-my-shell@aunetx
    clipboard-indicator@tudmotu.com
    caffeine@patapon.info
    rounded-window-corners@fxgn
)
# These ship with Zorin OS; other distros just skip them
EXTENSIONS_ZORIN=(
    zorin-magic-lamp-effect@zorinos.com
    zorin-window-move-effect@zorinos.com
    zorin-desktop-cube@zorinos.com
)

step_extensions() {
    step "GNOME extensions"
    local shellv; shellv="$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"
    for uuid in "${EXTENSIONS[@]}"; do
        if gnome-extensions info "$uuid" >/dev/null 2>&1; then ok "$uuid already there"; continue; fi
        local url
        url="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shellv" \
              | python3 -c 'import sys,json;print(json.load(sys.stdin).get("download_url",""))' 2>/dev/null)"
        if [ -z "$url" ]; then warn "$uuid has no build for GNOME $shellv"; continue; fi
        fetch "https://extensions.gnome.org$url" "$TMP/ext.zip" && gnome-extensions install --force "$TMP/ext.zip" \
            && ok "$uuid installed" || warn "$uuid failed"
    done
    # turn them all on; on Wayland a freshly installed extension only loads after logging out and back in
    python3 - "${EXTENSIONS[@]}" "${EXTENSIONS_ZORIN[@]}" <<'EOF'
import ast,subprocess,sys,re
out=subprocess.check_output(['gsettings','get','org.gnome.shell','enabled-extensions']).decode()
cur=ast.literal_eval(re.sub(r'^@as ','',out.strip()))
for u in sys.argv[1:]:
    if u not in cur: cur.append(u)
subprocess.run(['gsettings','set','org.gnome.shell','enabled-extensions',str(cur)],check=True)
EOF
    gsettings set org.gnome.shell.extensions.user-theme name 'Catppuccin-GnomeTheme' 2>/dev/null || true
    ok "extensions enabled (log out and back in to load them)"
}

step_wallpaper() {
    step "Wallpaper: waves"
    # drawn by scripts/make-wallpaper.py, so it ships with the repo
    local pics; pics="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Wallpapers/purrspace"
    mkdir -p "$pics" && cp "$F/wallpapers/waves.png" "$pics/waves.png"
    local w="$pics/waves.png"
    for k in picture-uri picture-uri-dark; do gsettings set org.gnome.desktop.background "$k" "file://$w"; done
    gsettings set org.gnome.desktop.background picture-options 'zoom'
    gsettings set org.gnome.desktop.screensaver picture-uri "file://$w"
    ok "applied ($w)"
}

step_terminal() {
    step "Terminal: WezTerm, tmux, fastfetch, Neovim, lazygit, fzf"
    keep "$HOME/.wezterm.lua"; cp "$F/wezterm.lua" "$HOME/.wezterm.lua"
    keep "$HOME/.tmux.conf";   cp "$F/tmux.conf" "$HOME/.tmux.conf"
    [ -d "$HOME/.tmux/plugins/tpm" ] || git clone -q https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    ok "WezTerm and tmux (inside tmux: Ctrl+b then I installs the plugins)"

    mkdir -p "$HOME/.config/fastfetch"; cp "$F"/fastfetch/* "$HOME/.config/fastfetch/"
    if ! has fastfetch; then
        local url
        url="$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
              | python3 -c 'import sys,json;print([a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if a["name"]=="fastfetch-linux-amd64.deb"][0])')"
        fetch "$url" "$TMP/ff.deb" && dpkg-deb -x "$TMP/ff.deb" "$TMP/ff" \
            && mkdir -p "$HOME/.local/bin" && cp "$TMP/ff/usr/bin/fastfetch" "$HOME/.local/bin/" && ok "fastfetch in ~/.local/bin"
    fi

    if [ -d "$HOME/.config/nvim/lua/plugins" ]; then
        keep "$HOME/.config/nvim/lua/plugins/colorscheme.lua"
        cp "$F/nvim/colorscheme.lua" "$HOME/.config/nvim/lua/plugins/" && ok "Neovim in Mocha"
    else
        warn "no Neovim (LazyVim) config found; its theme lives in files/nvim/colorscheme.lua"
    fi

    mkdir -p "$HOME/.config/lazygit"; keep "$HOME/.config/lazygit/config.yml"
    cp "$F/lazygit/config.yml" "$HOME/.config/lazygit/" && ok "lazygit in Mocha"

    mkdir -p "$HOME/.config/purrspace"; cp "$F/zsh/purrspace.zsh" "$HOME/.config/purrspace/purrspace.zsh"
    grep -q 'config/purrspace/purrspace.zsh' "$HOME/.zshrc" 2>/dev/null \
        || printf '\n# purrspace (fzf colors, spicetify)\n[ -f ~/.config/purrspace/purrspace.zsh ] && source ~/.config/purrspace/purrspace.zsh\n' >> "$HOME/.zshrc"
    ok "fzf in Mocha (new terminals)"
}

step_flatpak() {
    step "Flatpak apps: theme, traffic lights and cursor"
    has flatpak || { warn "flatpak is not installed"; return; }
    flatpak override --user \
        --filesystem="$HOME/.themes:ro" --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro \
        --filesystem="$HOME/.local/share/icons:ro" \
        --env=GTK_THEME=Catppuccin-GnomeTheme \
        --env=XCURSOR_PATH="$HOME/.local/share/icons:/usr/share/icons" \
        --env=XCURSOR_THEME=Bibata-Modern-Ice --env=XCURSOR_SIZE=24
    # Inside a Flatpak, GTK reads ~/.var/app/<app>/config/gtk-*, not ~/.config/gtk-*.
    # Without these links Chrome, Slack and VS Code never get the traffic lights.
    for app in $(flatpak list --app --columns=application); do
        local c="$HOME/.var/app/$app/config"
        for v in 3.0 4.0; do
            mkdir -p "$c/gtk-$v"
            ln -sfn "$HOME/.config/gtk-$v/gtk.css" "$c/gtk-$v/gtk.css"
            printf '[Settings]\ngtk-theme-name=Catppuccin-GnomeTheme\ngtk-application-prefer-dark-theme=1\n' > "$c/gtk-$v/settings.ini"
        done
        ln -sfn "$HOME/.config/gtk-4.0/catppuccin.css" "$c/gtk-4.0/catppuccin.css"
        ln -sfn "$HOME/.config/gtk-4.0/assets" "$c/gtk-4.0/assets"
    done
    ok "overrides and links for $(flatpak list --app --columns=application | wc -l) apps"

    local vs="$HOME/.var/app/com.visualstudio.code/config/Code/User/settings.json"
    if flatpak info com.visualstudio.code >/dev/null 2>&1; then
        keep "$vs"; $HELP vscode "$vs" "$F/vscode/purrspace.json"
        warn "VS Code: install the 'Catppuccin for VSCode' extension for the Mocha theme"
    fi
    local sl="$HOME/.var/app/com.slack.Slack/config/Slack/storage/root-state.json"
    if [ -f "$sl" ]; then
        flatpak kill com.slack.Slack 2>/dev/null; sleep 1
        keep "$sl"; $HELP slack-hide-menu "$sl"
    fi
}

step_spotify() {
    step "Spotify (user Flatpak) with Spicetify Catppuccin"
    # It has to be a --user Flatpak: in the Snap and in the system Flatpak the
    # Spotify files are read-only and Spicetify can't apply the theme.
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak info --user com.spotify.Client >/dev/null 2>&1 \
        || flatpak install --user -y --noninteractive flathub com.spotify.Client || return 1
    # Wayland with GTK-drawn decorations: the title bar gets the traffic lights.
    # (On X11 GNOME draws an unthemed bar.) The Flatpak launcher reads this file.
    local cfg="$HOME/.var/app/com.spotify.Client/config"
    mkdir -p "$cfg"
    printf '%s\n' '--enable-features=UseOzonePlatform,WaylandWindowDecorations' '--ozone-platform=wayland' > "$cfg/spotify-flags.conf"
    local prefs="$HOME/.var/app/com.spotify.Client/config/spotify/prefs"
    if [ ! -f "$prefs" ]; then
        (flatpak run --user com.spotify.Client >/dev/null 2>&1 &)
        for _ in $(seq 1 30); do [ -f "$prefs" ] && break; sleep 1; done
        sleep 3; flatpak kill com.spotify.Client 2>/dev/null
    fi
    if [ ! -x "$HOME/.spicetify/spicetify" ]; then
        local url
        url="$(curl -fsSL https://api.github.com/repos/spicetify/cli/releases/latest \
              | python3 -c 'import sys,json;print([a["browser_download_url"] for a in json.load(sys.stdin)["assets"] if a["name"].endswith("linux-amd64.tar.gz")][0])')"
        fetch "$url" "$TMP/spicetify.tgz" && mkdir -p "$HOME/.spicetify" && tar -xzf "$TMP/spicetify.tgz" -C "$HOME/.spicetify" || return 1
    fi
    local sp="$HOME/.spicetify/spicetify"
    "$sp" config-dir >/dev/null 2>&1 || true
    git clone -q --depth 1 https://github.com/catppuccin/spicetify "$TMP/ctp-sp" || return 1
    mkdir -p "$HOME/.config/spicetify/Themes" && cp -r "$TMP/ctp-sp/catppuccin" "$HOME/.config/spicetify/Themes/"
    "$sp" config spotify_path "$HOME/.local/share/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify" \
        prefs_path "$prefs" current_theme catppuccin color_scheme mocha \
        inject_css 1 inject_theme_js 1 replace_colors 1 overwrite_assets 1 >/dev/null
    "$sp" backup apply >/dev/null 2>&1 || "$sp" apply >/dev/null 2>&1 || return 1
    # Spotify was installed after the flatpak step ran, so link the GTK files for it too
    for v in 3.0 4.0; do
        mkdir -p "$cfg/gtk-$v"; ln -sfn "$HOME/.config/gtk-$v/gtk.css" "$cfg/gtk-$v/gtk.css"
        printf '[Settings]\ngtk-theme-name=Catppuccin-GnomeTheme\ngtk-application-prefer-dark-theme=1\n' > "$cfg/gtk-$v/settings.ini"
    done
    ln -sfn "$HOME/.config/gtk-4.0/catppuccin.css" "$cfg/gtk-4.0/catppuccin.css"
    ln -sfn "$HOME/.config/gtk-4.0/assets" "$cfg/gtk-4.0/assets"
    ok "Spotify in Catppuccin Mocha (the first launch is slow; a few seconds of loading is normal)"
}

step_obsidian() {
    step "Obsidian with the Catppuccin theme"
    local cfg="$HOME/.config/obsidian/obsidian.json"
    [ -f "$cfg" ] || { warn "no Obsidian vault yet; open Obsidian once, then run: ./install.sh obsidian"; return; }
    python3 -c 'import json,sys;[print(v["path"]) for v in json.load(open(sys.argv[1])).get("vaults",{}).values()]' "$cfg" \
    | while IFS= read -r vault; do
        local t="$vault/.obsidian/themes/Catppuccin"; mkdir -p "$t"
        fetch https://raw.githubusercontent.com/catppuccin/obsidian/main/theme.css "$t/theme.css" \
          && fetch https://raw.githubusercontent.com/catppuccin/obsidian/main/manifest.json "$t/manifest.json" \
          && $HELP obsidian "$vault"
    done
}

step_apps() {
    step "App grid folders, favorites and custom icons"
    $HELP app-folders
    $HELP favorites
    # Mocha icons for the dock apps. A copy of each .desktop file goes to
    # ~/.local/share/applications with a new Icon=; the originals stay untouched.
    mkdir -p "$ICONS/hicolor/scalable/apps" "$HOME/.local/share/applications"
    local dirs=("$HOME/.local/share/applications" "$HOME/.local/share/flatpak/exports/share/applications"
                /var/lib/flatpak/exports/share/applications /usr/share/applications)
    local pair pattern icon src d f
    for pair in 'com.google.Chrome:chrome' 'com.visualstudio.code:vscode' 'com.slack.Slack:slack' \
                'org.wezfurlong.wezterm:wezterm' 'org.gnome.Nautilus:files' 'agentes.chat:agentes' \
                't3code:t3' 'org.telegram.desktop*:telegram' 'com.spotify.Client:spotify'; do
        pattern="${pair%%:*}"; icon="purr-${pair##*:}"; src=""
        for d in "${dirs[@]}"; do
            for f in "$d"/$pattern.desktop; do [ -f "$f" ] && { src="$f"; break 2; }; done
        done
        [ -n "$src" ] || continue
        cp "$F/icons/$icon.svg" "$ICONS/hicolor/scalable/apps/"
        local dest="$HOME/.local/share/applications/$(basename "$src")"
        [ "$src" = "$dest" ] && keep "$src"
        sed "s/^Icon=.*/Icon=$icon/" "$src" > "$dest.tmp" && mv "$dest.tmp" "$dest"
        ok "$(basename "$src" .desktop) icon"
    done
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
}

STEPS=(backup fonts cursor theme icons extensions wallpaper terminal flatpak spotify obsidian apps)

# ---------------------------------------------------------------- run

if [ "${1:-}" = "--list" ]; then printf '%s\n' "${STEPS[@]}"; exit 0; fi
for c in curl git python3 gsettings dconf; do has "$c" || { echo "missing command: $c"; exit 1; }; done
[ "${XDG_CURRENT_DESKTOP:-}" = "${XDG_CURRENT_DESKTOP/GNOME/}" ] && { echo "purrspace is for GNOME."; exit 1; }

WANTED=("$@"); [ ${#WANTED[@]} -eq 0 ] && WANTED=("${STEPS[@]}")
for s in "${WANTED[@]}"; do
    if ! declare -F "step_$s" >/dev/null; then warn "unknown step: $s"; continue; fi
    "step_$s" || { FAILED+=("$s"); warn "step '$s' failed, moving on"; }
done

echo
if [ ${#FAILED[@]} -gt 0 ]; then
    warn "Failed: ${FAILED[*]}. Run just those again: ./install.sh ${FAILED[*]}"
fi
cat <<'EOF'

A few things are left for you (the README explains each one):
  1. Log out and back in (loads the extensions).
  2. Chrome: Settings → Appearance → Mode → GTK, then chrome://restart.
  3. VS Code: install the "Catppuccin for VSCode" extension.
  4. Telegram: open https://t.me/addtheme/ctp_mocha
  5. Slack: custom theme with the colors from the README.

Purr. 🐾
EOF
