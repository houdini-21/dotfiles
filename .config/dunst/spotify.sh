#!/bin/bash

# Carpeta temporal para la carátula
tmp_dir="/tmp/spotify_notif"
mkdir -p "$tmp_dir"

# Escuchar cambios de metadatos
playerctl --player=spotify metadata --format '{{title}}||{{artist}}||{{mpris:artUrl}}' --follow | while read -r line; do
    
    # Parsear los datos
    IFS="||" read -r title artist art_url <<< "$line"
    
    # Descargar la imagen si existe
    img_path="$tmp_dir/cover.png"
    if [[ "$art_url" == file://* ]]; then
        cp "${art_url#file://}" "$img_path"
    else
        wget -qO "$img_path" "$art_url"
    fi

    # Enviar a Dunst
    # -i: icono/imagen, -a: nombre app, -r: reemplaza la anterior para no llenar la pantalla
    notify-send -i "$img_path" -a "Spotify" -r 9991 "$title" "👤 $artist"
done
