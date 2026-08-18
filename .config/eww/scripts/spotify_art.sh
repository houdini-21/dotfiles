#!/usr/bin/env bash
# Sigue el arte del álbum del reproductor activo y genera una versión
# difuminada para el fondo del widget de música.
# Salida: {"art": "<ruta>", "blur": "<ruta>"}

# playerctld hace que playerctl apunte siempre al reproductor activo
# (sin él, con spotify + chromium abiertos gana el primero de la lista)
pgrep -x playerctld >/dev/null || setsid -f playerctld daemon >/dev/null 2>&1

cache_dir="$XDG_RUNTIME_DIR/album_art_cache"
mkdir -p "$cache_dir"

emit() {
    echo "{\"art\":\"$1\",\"blur\":\"$2\"}"
}

playerctl metadata --format "{{mpris:artUrl}}" --follow | while IFS= read -r line; do
    if [[ -z $line ]]; then
        emit "" ""
        continue
    fi

    # Nombre único por URL (los thumbnails de youtube comparten basename)
    hash=$(printf '%s' "$line" | md5sum | cut -d' ' -f1)
    file_path="$cache_dir/$hash"
    blur_path="$cache_dir/${hash}_blur.png"

    if [[ $line == http* ]]; then
        [ -s "$file_path" ] || curl -s --max-time 10 --output "$file_path" "$line"
    elif [[ $line == file://* ]]; then
        [ -s "$file_path" ] || cp -f "${line#file://}" "$file_path" 2>/dev/null
    else
        emit "" ""
        continue
    fi

    if [ -s "$file_path" ]; then
        [ -s "$blur_path" ] || magick "$file_path" -resize 400x400^ -gravity center -extent 400x400 -blur 0x12 "$blur_path" 2>/dev/null
        if [ -s "$blur_path" ]; then
            emit "$file_path" "$blur_path"
        else
            emit "$file_path" ""
        fi
    else
        emit "" ""
    fi
done
