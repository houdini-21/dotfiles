#!/bin/bash

NOTIFY_ID=999
RAM_DIR="/run/user/$(id -u)/spotify_cache"
mkdir -p "$RAM_DIR"

playerctl --player=spotify metadata --format '{{title}}|{{artist}}|{{mpris:artUrl}}' --follow | while IFS='|' read -r title artist art_url; do
    
    if [ -z "$title" ]; then continue; fi

    filename=$(echo "${artist}_${title}" | sed 's/[^A-Za-z0-9._-]/_/g' | cut -c1-50)
    local_art="$RAM_DIR/${filename}.png"

    if [[ "$art_url" == http* ]]; then
        if [ ! -f "$local_art" ]; then
            curl -sL "$art_url" -o "$local_art"
        fi
        icon_param="$local_art"
    else
        icon_param="spotify"
    fi

    dunstify -a "Spotify" -i "$icon_param" -r "$NOTIFY_ID" "$title" "$artist"

done