#!/bin/sh
workspaces() {
~/.config/eww/scripts/workspaces.py
}
workspaces
#Cleanup Creating
tail -f /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log | grep --line-buffered "Set keyboard focus\|Keybind triggered\|Destroying\|Creating" | while read -r; do 
workspaces
done
