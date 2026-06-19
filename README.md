# 🍚 dotfiles

My personal **Arch Linux + bspwm** rice — Catppuccin Mocha (Teal) themed.

| | |
|---|---|
| **OS** | Arch Linux |
| **WM** | [bspwm](https://github.com/baskerville/bspwm) |
| **Hotkeys** | [sxhkd](https://github.com/baskerville/sxhkd) |
| **Bar** | [polybar](https://github.com/polybar/polybar) (multi-theme) + [eww](https://github.com/elkowar/eww) widgets |
| **Compositor** | [picom](https://github.com/yshui/picom) (ftlabs/pijulius fork) |
| **Launcher** | [rofi](https://github.com/davatorium/rofi) + greenclip |
| **Notifications** | [dunst](https://github.com/dunst-project/dunst) |
| **Wallpaper** | [nitrogen](https://github.com/l3ib/nitrogen) |
| **Terminal** | [kitty](https://sw.kovidgoyal.net/kitty/) |
| **Shell** | zsh + [starship](https://starship.rs/) + [fastfetch](https://github.com/fastfetch-cli/fastfetch) |
| **Monitor** | [btop](https://github.com/aristocratos/btop) |
| **Theme** | Catppuccin Mocha (Teal) — GTK, cursors, kitty |
| **Fonts** | OperatorMono Nerd Font, JetBrains Mono Nerd Font, Noto |

---

## 📦 What's included

```
.config/
├── bspwm/        # window manager (bspwmrc)
├── sxhkd/        # keybindings (sxhkdrc) + volume script
├── polybar/      # status bars (many adi1090x-style themes)
├── eww/          # widgets: control center, weather, notifications, hardware
├── picom/        # compositor (blur, shadows, animations)
├── dunst/        # notifications + spotify cover script
├── rofi/         # launcher with many color themes
├── kitty/        # terminal (Catppuccin themes, 0.75 opacity)
├── nitrogen/     # wallpaper manager
├── btop/ fastfetch/ flameshot/ nwg-look/ xsettingsd/ mpv/
├── gtk-2.0/ gtk-3.0/ gtk-4.0/ fontconfig/
└── starship.toml, greenclip.toml, mimeapps.list
wallpapers/       # the wallpaper set (referenced by nitrogen + fastfetch)
.zshrc .bashrc .bash_profile .xinitrc .Xresources .gtkrc-2.0
```

---

## 🚀 Install

> ⚠️ Run on a fresh-ish setup. The installer **backs up** anything it replaces to
> `~/.dotfiles-backup/<timestamp>/`, but review it first.

**1. Install the packages** (Arch / `pacman` + AUR helper such as `yay`):

```bash
# Core rice (official repos)
sudo pacman -S --needed bspwm sxhkd polybar picom dunst rofi nitrogen \
  kitty fastfetch btop flameshot nwg-look xsettingsd feh jq eza playerctl \
  zsh zsh-autocomplete zsh-syntax-highlighting zsh-autosuggestions \
  starship noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd

# AUR
yay -S eww rofi-greenclip catppuccin-gtk-theme-mocha catppuccin-cursors-mocha
# OperatorMono Nerd Font — install manually (used by kitty); or change the font in kitty.conf
```

**2. Clone and link:**

```bash
git clone https://github.com/fmarinero-designli/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

**3. Start X** (the included `.xinitrc` just does `exec bspwm`):

```bash
startx
```

---

## 🔧 Notes / things to tweak

- **Monitors:** `.config/bspwm/bspwmrc` is hardcoded for a **dual 2560×1440@165Hz** setup
  (`DP-2` + `DP-4`). Edit the `xrandr` / `bspc monitor` lines for your displays.
- **Weather widget:** add your own free [OpenWeatherMap](https://openweathermap.org/api) key
  in `.config/eww/scripts/weather.sh` (`KEY=...`) and set `LAT`/`LON`/`ID` for your city.
  (My key was removed before publishing.)
- **Wallpaper:** `install.sh` copies `wallpapers/` into `~/Images`. nitrogen restores
  `~/Images/afternoon.jpg` by default — change it via `nitrogen` or `nitrogen/bg-saved.cfg`.
- **Polybar theme:** launch with e.g. `~/.config/polybar/launch.sh --cuts` (see the script
  for all styles). The eww bars are opened from `bspwmrc`.
- **Shell:** `.zshrc` expects `eza`, `starship`, `fastfetch`, `nvm`, and `pnpm`. Comment out
  what you don't use.

---

*Made with ❤️ on Arch. PRs/forks welcome.*
