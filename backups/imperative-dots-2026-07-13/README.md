# imperative-dots-backup

Backup **privado** del rice Hyprland que instalé el 13-jul-2026 y revertí ese mismo día.
En la máquina original sigue en `~/.imperative-dots-reverted-20260713`.

## Origen

| | |
|---|---|
| Upstream | [ilyamiro/imperative-dots](https://github.com/ilyamiro/imperative-dots) (rama `master`) |
| Commit instalado | `eefff2fadceb28b52198175914576fbb55f57695` |
| Versión | `1.7.6-1` |
| Licencia | el upstream **no declara ninguna** → esto es un backup personal, no una redistribución |

> El autor movió el proyecto a `ilyamiro/serpantinum`.

## Contenido

```
config/                  # lo que el instalador dejó en ~/.config/
├── hypr/                # Hyprland + shell propio en Quickshell (~30 QML: barra,
│                        #   launcher, calendario, portapapeles, música, red,
│                        #   notificaciones, lock, wallpapers, settings)
├── cava/ gtk-3.0/ gtk-4.0/ kitty/ matugen/ nvim/ qt5ct/ qt6ct/ zsh/
imperative-dots-version   # estado del instalador (elección de driver, layouts, unit de weather)
zshrc.as-left-by-script   # el .zshrc tal como quedó tras correr el script
```

## Qué NO está acá

- **Los 319 wallpapers** (~415 MB): viven aparte, no tiene sentido versionarlos.
- La clave real de OpenWeatherMap: saneada a `TU_API_KEY_AQUI` en `imperative-dots-version` y en
  `config/hypr/scripts/quickshell/calendar/.env` antes del primer commit.
- El `calendar/.env` en sí: la regla `.env` del `.gitignore` del repo lo deja fuera (a propósito).
  Su estructura queda documentada en `config/hypr/scripts/quickshell/calendar/.env.example`.

## Por qué se revirtió

Se instaló como prueba el 13-jul-2026 y se deshizo el mismo día (el script había reescrito el
`.zshrc`); la máquina volvió a bspwm/X11, que es el entorno de trabajo actual.
