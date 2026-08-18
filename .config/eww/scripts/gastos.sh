#!/bin/sh
# Refresca los datos de gastos-agent y alterna el popup.
# Llamado por la pill de gastos en la barra (modules/gastos.yuck).

echo "$(date '+%H:%M:%S') click recibido" >> /tmp/gastos-eww.log

json="$("$HOME/gastos-agent/.venv/bin/python" "$HOME/gastos-agent/main.py" status --json 2>>/tmp/gastos-eww.log)"
if [ -n "$json" ]; then
    eww update gastos="$json" 2>>/tmp/gastos-eww.log
fi

eww open --toggle gastos_popup 2>>/tmp/gastos-eww.log
echo "$(date '+%H:%M:%S') toggle ejecutado" >> /tmp/gastos-eww.log
