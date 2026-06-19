#!/bin/bash

# Asegura que Nitrogen sepa a qué pantalla de X11 conectarse
export DISPLAY=:0

# Ruta a tus imágenes (Asegúrate de que la ruta sea la correcta)
DIR="$HOME/Images"

# Obtener la hora actual
HOUR=$(date +%H)

# Función para aplicar el wallpaper en ambos monitores
set_wallpaper() {
    # --head=0 es el primer monitor, --head=1 es el segundo
    nitrogen --head=0 --set-zoom-fill --save "$DIR/$1" 2>/dev/null
    nitrogen --head=1 --set-zoom-fill --save "$DIR/$1" 2>/dev/null

    nitrogen --restore 2>/dev/null
}

if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 12 ]; then
    # Morning (6:00 AM - 12:00 PM)
    set_wallpaper "morning.jpg"
elif [ "$HOUR" -ge 12 ] && [ "$HOUR" -lt 16 ]; then
    # Afternoon (12:00 PM - 4:00 PM)
    set_wallpaper "afternoon.jpg"
elif [ "$HOUR" -ge 16 ] && [ "$HOUR" -lt 19 ]; then
    # Evening (4:00 PM - 7:00 PM)
    set_wallpaper "evening.jpg"
else
    # Night (7:00 PM en adelante)
    set_wallpaper "night.jpg"
fi
