#!/bin/sh
workspaces() {

ws1="1"; ws2="2"; ws3="3"; ws4="4"; ws5="5"; ws6="6"; ws7="7"

# Check Occupied
o1=$(bspc query -D -d .occupied --names | grep "$ws1")
o2=$(bspc query -D -d .occupied --names | grep "$ws2")
o3=$(bspc query -D -d .occupied --names | grep "$ws3")
o4=$(bspc query -D -d .occupied --names | grep "$ws4")
o5=$(bspc query -D -d .occupied --names | grep "$ws5")
o6=$(bspc query -D -d .occupied --names | grep "$ws6")
o7=$(bspc query -D -d .occupied --names | grep "$ws7")

# Check Focused
f1=$(bspc query -D -d focused --names | grep "$ws1")
f2=$(bspc query -D -d focused --names | grep "$ws2")
f3=$(bspc query -D -d focused --names | grep "$ws3")
f4=$(bspc query -D -d focused --names | grep "$ws4")
f5=$(bspc query -D -d focused --names | grep "$ws5")
f6=$(bspc query -D -d focused --names | grep "$ws6")
f7=$(bspc query -D -d focused --names | grep "$ws7")

ic_1=""; ic_2=""; ic_3=""; ic_4=""; ic_5=""; ic_6=""; ic_7=""
[ $f1 ] && ic_1=""; [ $f2 ] && ic_2=""; [ $f3 ] && ic_3=""; [ $f4 ] && ic_4=""; [ $f5 ] && ic_5=""; [ $f6 ] && ic_6=""; [ $f7 ] && ic_7=""

# Función interna para nombres de clase coherentes
get_class() {
    if [ "$1" ]; then echo "focused"; elif [ "$2" ]; then echo "occupied"; else echo "empty"; fi
}

echo "(box :class \"workspaces\" :orientation \"h\" :spacing 5 :space-evenly \"false\" :halign \"center\" :valign \"center\" \
(button :onclick \"bspc desktop -f $ws1\" :class \"$(get_class $f1 $o1)\" \"$ic_1\") \
(button :onclick \"bspc desktop -f $ws2\" :class \"$(get_class $f2 $o2)\" \"$ic_2\") \
(button :onclick \"bspc desktop -f $ws3\" :class \"$(get_class $f3 $o3)\" \"$ic_3\") \
(button :onclick \"bspc desktop -f $ws4\" :class \"$(get_class $f4 $o4)\" \"$ic_4\") \
(button :onclick \"bspc desktop -f $ws5\" :class \"$(get_class $f5 $o5)\" \"$ic_5\") \
(button :onclick \"bspc desktop -f $ws6\" :class \"$(get_class $f6 $o6)\" \"$ic_6\") \
(button :onclick \"bspc desktop -f $ws7\" :class \"$(get_class $f7 $o7)\" \"$ic_7\"))"
}

workspaces
bspc subscribe desktop node_transfer node_add node_remove | while read -r _ ; do
workspaces
done