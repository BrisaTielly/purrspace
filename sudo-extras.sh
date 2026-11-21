#!/usr/bin/env bash
# purrspace extras that need root. Optional: install.sh never calls this.
#
#   sudo ./sudo-extras.sh            # all of them
#   sudo ./sudo-extras.sh login t3   # just those
#
#   t3     keep T3 Code on the system title bar, re-patched after every update
#   login  the login screen in Mocha: Zorin's own theme recolored, waves as background
#   boot   Catppuccin Mocha boot splash (catppuccin/plymouth)
#
# Undo:
#   login  sudo update-alternatives --auto gdm-theme.gresource   (after removing ours:
#          sudo update-alternatives --remove gdm-theme.gresource /usr/share/gnome-shell/theme/purrspace-mocha/gnome-shell-theme.gresource)
#   boot   sudo update-alternatives --auto default.plymouth && sudo update-initramfs -u
#   t3     sudo systemctl disable --now t3-bolinhas.path
set -uo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
cd "$(dirname "$0")"
R="$PWD"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ok()   { echo "  ok    $*"; }
fail() { echo "  FAIL  $*"; }

step_t3() {
    install -m 755 scripts/t3-traffic-lights.py /usr/local/sbin/t3-bolinhas || return 1
    cat > /etc/systemd/system/t3-bolinhas.service <<'EOF'
[Unit]
Description=Give T3 Code the system title bar (traffic lights)

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /usr/local/sbin/t3-bolinhas
SuccessExitStatus=10 20
EOF
    cat > /etc/systemd/system/t3-bolinhas.path <<'EOF'
[Unit]
Description=Watch T3 Code's app.asar for updates

[Path]
PathChanged=/opt/T3 Code (Beta)/resources/app.asar

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload && systemctl enable --now t3-bolinhas.path && systemctl start t3-bolinhas.service
}

step_login() {
    # Start from the theme GDM uses now, so every asset it expects is still there
    local base; base="$(readlink -f /usr/share/gnome-shell/gdm-theme.gresource)"
    case "$base" in */purrspace-mocha/*) base=/usr/share/gnome-shell/theme/ZorinBlue-Dark/gnome-shell-theme.gresource ;; esac
    [ -f "$base" ] || { echo "no GDM theme found"; return 1; }
    command -v glib-compile-resources >/dev/null || apt-get install -y libglib2.0-dev-bin || return 1
    local x="$TMP/gdm"
    for r in $(gresource list "$base"); do
        mkdir -p "$x/$(dirname "${r#/org/gnome/shell/theme/}")"
        gresource extract "$base" "$r" > "$x/${r#/org/gnome/shell/theme/}"
    done
    python3 - "$x" <<'EOF'
import re, sys, os
x = sys.argv[1]
# Zorin's blue-grey palette -> Catppuccin Mocha
m = {'#bde6fb': '#cba6f7', '#161c1f': '#11111b', '#2d3940': '#1e1e2e', '#222b30': '#181825',
     '#35434a': '#313244', '#3d4c54': '#45475a', '#3c4b53': '#45475a', '#43545c': '#585b70',
     '#6f8896': '#6c7086', '#a0c2d4': '#b4befe', '#fb7c7c': '#f38ba8', '#faa483': '#fab387'}
for f in ('gdm.css', 'gnome-shell.css'):
    p = os.path.join(x, f)
    if not os.path.exists(p):
        continue
    s = open(p).read()
    for a, b in m.items():
        s = re.sub(re.escape(a), b, s, flags=re.I)
    s += ("\n/* purrspace: Mocha login */\n"
          ".login-dialog-prompt-entry { caret-color: #f5c2e7; selection-background-color: #cba6f7; }\n"
          ".unlock-dialog-clock .unlock-dialog-clock-time { font-weight: bold; }\n")
    open(p, 'w').write(s)
EOF
    [ -f "$x/assets/login-background.png" ] && cp "$R/files/wallpapers/waves.png" "$x/assets/login-background.png"
    { echo '<?xml version="1.0" encoding="UTF-8"?><gresources><gresource prefix="/org/gnome/shell/theme">'
      (cd "$x" && find . -type f | sed 's|^\./||' | sort | sed 's|.*|<file>&</file>|')
      echo '</gresource></gresources>'; } > "$TMP/gdm.xml"
    glib-compile-resources --sourcedir="$x" --target="$TMP/gdm.gresource" "$TMP/gdm.xml" || return 1
    diff <(gresource list "$TMP/gdm.gresource") <(gresource list "$base") >/dev/null \
        || { echo "built theme is missing files; not installing"; return 1; }
    local dest=/usr/share/gnome-shell/theme/purrspace-mocha/gnome-shell-theme.gresource
    install -D -m 644 "$TMP/gdm.gresource" "$dest"
    update-alternatives --install /usr/share/gnome-shell/gdm-theme.gresource gdm-theme.gresource "$dest" 30
    update-alternatives --set gdm-theme.gresource "$dest"
}

step_boot() {
    git clone -q --depth 1 https://github.com/catppuccin/plymouth "$TMP/plymouth" || return 1
    local T=/usr/share/plymouth/themes/catppuccin-mocha
    mkdir -p $T && install -m 644 "$TMP"/plymouth/themes/catppuccin-mocha/* $T/ || return 1
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth $T/catppuccin-mocha.plymouth 200
    update-alternatives --set default.plymouth $T/catppuccin-mocha.plymouth && update-initramfs -u
}

STEPS=(t3 login boot)
[ $# -gt 0 ] && STEPS=("$@")
for s in "${STEPS[@]}"; do
    echo "== $s"
    if "step_$s"; then ok "$s"; else fail "$s"; fi
done
echo "Log out to see the login screen; reboot to see the boot splash."
