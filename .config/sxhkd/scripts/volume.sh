#!/bin/bash

# Colores Catppuccin Mocha
BLUE="#89b4fa"
RED="#f38ba8"
TEXT="#cdd6f4"

function get_volume {
    pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -n 1
}

function is_mute {
    pactl get-sink-mute @DEFAULT_SINK@ | grep -q "yes"
}

function send_notification {
    volume=$(get_volume)
    [ -z "$volume" ] && volume=0
    
    icon="󰕾"
    
    # IMPORTANTE: dunstify necesita dos argumentos de texto: "Resumen" y "Cuerpo".
    # Como tu format es solo "%b", ponemos el texto en el segundo argumento.
    dunstify -t 2000 \
             -h int:value:"$volume" \
             -h string:hlcolor:"$BLUE" \
             "Volumen" "<span foreground='$BLUE' font='14'>$icon</span> <span foreground='$TEXT'>Volumen: $volume%</span>" -r 21
}

case $1 in
    up)
        pactl set-sink-mute @DEFAULT_SINK@ false
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        send_notification
        ;;
    down)
        pactl set-sink-mute @DEFAULT_SINK@ false
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        send_notification
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        if is_mute ; then
            icon_mute="󰖁"
            dunstify -t 2000 \
                     -h string:hlcolor:"$RED" \
                     "Mute" "<span foreground='$RED' font='14'>$icon_mute</span> <span foreground='$RED'>Muteado</span>" -r 21
        else
            send_notification
        fi
        ;;
esac
