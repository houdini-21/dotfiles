#!/bin/bash
# Estado y toggles para los Quick Settings del Control Center

wifi_status() { [ "$(nmcli radio wifi)" = "enabled" ] && echo "on" || echo "off"; }
bt_status()   { bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo "on" || echo "off"; }
dnd_status()  { [ "$(dunstctl is-paused)" = "true" ] && echo "on" || echo "off"; }

case "$1" in
    wifi-status) wifi_status ;;
    wifi-toggle)
        if [ "$(wifi_status)" = "on" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi
        eww update wifi_state="$(wifi_status)"
        ;;

    bt-status) bt_status ;;
    bt-toggle)
        if [ "$(bt_status)" = "on" ]; then bluetoothctl power off; else bluetoothctl power on; fi
        eww update bt_state="$(bt_status)"
        ;;

    dnd-status) dnd_status ;;
    dnd-toggle)
        dunstctl set-paused toggle
        eww update dnd_state="$(dnd_status)"
        ;;

    screenshot)
        # Cerramos el panel para que no salga en la captura
        eww close control_center
        sleep 0.2
        flameshot gui
        ;;
esac
