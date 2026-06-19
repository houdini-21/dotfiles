#!/usr/bin/env bash
#
# Dotfiles installer — symlinks every config into place.
# Anything it would overwrite is moved to ~/.dotfiles-backup/<timestamp>/ first,
# so this is safe to run on a machine that already has configs.
#
# Usage:  ./install.sh
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.dotfiles-backup/$TS"

link() {
  local src="$1" dest="$2" rel
  rel="${dest#"$HOME"/}"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "  ok    ~/$rel"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$(dirname "$BACKUP/$rel")"
    mv "$dest" "$BACKUP/$rel"
    echo "  bak   ~/$rel -> backup"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "  link  ~/$rel"
}

echo "Installing dotfiles from: $DOTFILES"
mkdir -p "$HOME/.config"

echo "==> ~/.config"
for item in "$DOTFILES"/.config/*; do
  name="$(basename "$item")"
  # systemd is handled per-unit below so we don't clobber other user units
  [ "$name" = "systemd" ] && continue
  link "$item" "$HOME/.config/$name"
done

echo "==> home dotfiles"
for f in .zshrc .bashrc .bash_profile .xinitrc .Xresources .gtkrc-2.0; do
  [ -e "$DOTFILES/$f" ] && link "$DOTFILES/$f" "$HOME/$f"
done

echo "==> ~/scripts"
link "$DOTFILES/scripts" "$HOME/scripts"

echo "==> systemd --user units (per-file, leaves your other units alone)"
if command -v systemctl >/dev/null 2>&1; then
  mkdir -p "$HOME/.config/systemd/user"
  for unit in "$DOTFILES"/.config/systemd/user/*; do
    link "$unit" "$HOME/.config/systemd/user/$(basename "$unit")"
  done
  systemctl --user daemon-reload || true
  systemctl --user enable --now wallpaper.timer spotify-notifications.service 2>/dev/null \
    && echo "  enabled wallpaper.timer + spotify-notifications.service" \
    || echo "  (enable later with: systemctl --user enable --now wallpaper.timer spotify-notifications.service)"
else
  echo "  systemctl not found — skipping"
fi

echo "==> wallpapers -> ~/Images (copied, not symlinked; existing files kept)"
mkdir -p "$HOME/Images"
for w in "$DOTFILES"/wallpapers/*; do
  dest="$HOME/Images/$(basename "$w")"
  if [ -e "$dest" ]; then echo "  keep  ~/Images/$(basename "$w")"; else cp "$w" "$dest"; echo "  copy  ~/Images/$(basename "$w")"; fi
done

echo
echo "Done."
[ -d "$BACKUP" ] && echo "Replaced files were backed up to: $BACKUP"
cat <<'EOF'

Next steps:
  - Add your OpenWeatherMap key in ~/.config/eww/scripts/weather.sh (KEY=...)
  - Reload the WM:   bspc wm -r     (or log out and back in)
  - Reload sxhkd:    pkill -USR1 -x sxhkd
  - See README.md for the package list to install first.
EOF
