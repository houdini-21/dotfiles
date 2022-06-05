#!/bin/sh

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps

if [ -f $sysresources ]; then
    xrdb -merge $sysresources
fi

if [ -f $sysmodmap ]; then
    xmodmap $sysmodmap
fi

if [ -f "$userresources" ]; then
    xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
    xmodmap "$usermodmap"
fi

# start some nice programs

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
 for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
  [ -x "$f" ] && . "$f"
 done
 unset f
fi

#screens
hdmi=`xrandr | grep ' connected' | grep 'HDMI' | awk '{print $1}'`

if [ "$hdmi" = "HDMI1" ]; then
    xrandr --output eDP1 --primary --mode 1366x768 --pos 0x0 --rotate normal --output DP1 --off --output DP2 --off --output HDMI1 --mode 1920x1080 --pos 1366x0 --rotate normal --output HDMI2 --off --output VIRTUAL1 --off &
else
  xrandr --output eDP1 --primary --mode 1366x768 --pos 0x0 --rotate normal --output HDMI1 --off --output DP1 --off &
fi


picom --experimental-backends &
#feh --bg-scale --bg-fill Wallpapers/wallpaper.jpg &
feh --bg-scale --bg-fill ./Wallpapers/wallpaper1.jpg --bg-scale --bg-fill ./Wallpapers/wallpaper.jpg
#udiskie -t &
nm-applet &
#blueman-applet &
#cbatticon 1 &
#volumeicon &
