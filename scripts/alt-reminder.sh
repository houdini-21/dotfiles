#!/bin/bash
# alt-reminder.sh — Notificaciones de escritorio de Alt para Fernando
# Uso: alt-reminder.sh <tipo>   (standup|walk|stretch|strength|saturday|switch2)
#      alt-reminder.sh --print <tipo>  (imprime sin notificar, para probar)
# Resuelve DISPLAY/DBUS aunque lo llame systemd (no hereda tu sesión).

MODE=notify
[ "$1" = "--print" ] && { MODE=print; shift; }

TIPO="${1:-standup}"
case "$TIPO" in
  standup)  TITLE="Alt: pausa anti-silla"; MSG="Levántate 2-3 min. Estira espalda, flexores de cadera y cuello. Tu columna lo agradece." ;;
  walk)     TITLE="Alt: caminata 30 min"; MSG="Zona de quema (117-137 bpm). Agua lejos del escritorio y a caminar." ;;
  stretch)  TITLE="Alt: estiramiento"; MSG="5 min: cuello, hombros y pecho en el marco de la puerta. El cuello de dev no se quita solo." ;;
  strength) TITLE="Alt: rutina anti-lagarto"; MSG="15 min suaves. Lun=core, Mie=postura, Vie=full body. Deja 2-3 reps en el tanque y estira al final. A las 6am nadie te juzga." ;;
  saturday) TITLE="Alt: actividad libre"; MSG="45-60 min de algo sin pantalla. Tu futuro yo lo agradece." ;;
  switch2)  TITLE="Alt: el case del Switch 2"; MSG="Llevas días viéndolo jugar. ¿Portátil o dock? Si la saca del dock: Killswitch Travel USD 79.85. Si vive en el mueble: ZenGrip 2 USD 69.99. Y no pagues el kit Ultra — el vidrio ya lo tenés." ;;
  *)        echo "Tipo desconocido: $TIPO"; exit 2 ;;
esac

if [ "$MODE" = "print" ]; then
  echo "TITLE: $TITLE"; echo "MSG: $MSG"; exit 0
fi

export DISPLAY="${DISPLAY:-:0}"
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  # Bus estándar de systemd user session
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

send() { notify-send -a "Alt" -i dialog-information "$1" "$2"; }

if ! send "$TITLE" "$MSG" 2>/dev/null; then
  # Si el bus no sirve, robamos la DBUS de un proceso gráfico vivo
  for p in polybar bspwm dunst; do
    pid=$(pgrep -u "$USER" -x "$p" 2>/dev/null | head -1)
    [ -z "$pid" ] && continue
    addr=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep '^DBUS_SESSION_BUS_ADDRESS=' | cut -d= -f2-)
    if [ -n "$addr" ]; then
      DBUS_SESSION_BUS_ADDRESS="$addr" notify-send -a "Alt" -i dialog-information "$TITLE" "$MSG" && exit 0
    fi
  done
  exit 1
fi
