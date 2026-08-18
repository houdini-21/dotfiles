#!/bin/bash

get_notifications() {
    RAW_HIST=$(dunstctl history)
    COUNT=$(echo "$RAW_HIST" | jq '.data[0] | length' 2>/dev/null || echo 0)

    if [ "$COUNT" -eq 0 ]; then
        echo "(label :class \"notifications-widget__empty\" :text \"No notifications\")"
    else
        echo "$RAW_HIST" | jq -r '
            # Quita etiquetas Pango (<span ...>, <b>, ...), decodifica entidades y escapa para yuck
            def clean:
                gsub("<[^>]*>"; "")
                | gsub("&lt;"; "<") | gsub("&gt;"; ">")
                | gsub("&quot;"; "\"") | gsub("&apos;"; "'\''") | gsub("&amp;"; "&")
                | gsub("\""; "\\\"") | gsub("\n"; " ");

            "(box :orientation \"v\" :spacing 10 " +
            ([.data[0][] |
                ((.body.data // "") | clean) as $body_clean |
                ((.summary.data // "Notificación") | clean) as $title_clean |
                ((.appname.data // "SISTEMA") | ascii_upcase) as $app_name |
                (.icon_path.data // "") as $icon |

                "(box :class \"notifications-widget__item\" :orientation \"h\" :space-evenly false :spacing 12 :tooltip \"" + $body_clean + "\" " +
                    # Solo agregamos el box de imagen si existe una ruta
                    (if $icon != "" then 
                        "(box :class \"notifications-widget__img\" :style \"background-image: url('\''" + $icon + "'\'');\") " 
                    else "" end) +
                    
                    "(box :orientation \"v\" :space-evenly false :hexpand true " +
                        "(label :class \"notifications-widget__app\" :text \"" + $app_name + "\" :halign \"start\") " +
                        "(label :class \"notifications-widget__title\" :text \"" + $title_clean + "\" :halign \"start\" :limit-width 25) " +
                        "(label :class \"notifications-widget__body\" :text \"" + $body_clean + "\" :halign \"start\" :wrap true :limit-width 80 :show-truncated true)" +
                    ")" +
                ")"
            ] | join(" ")) + 
            ")"
        '
    fi
}

case "$1" in
    "--clear") dunstctl history-clear ;;
    *) get_notifications ;;
esac