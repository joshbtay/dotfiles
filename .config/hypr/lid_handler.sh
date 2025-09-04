#!/usr/bin/env bash

# Simple clamshell mode for Hyprland
# Based on https://bobbys.zone/guides/hyprland-clamshell

if [[ "$(hyprctl monitors)" =~ DP-[0-9]+ ]]; then
    if [[ $1 == "open" ]]; then
        hyprctl keyword monitor "eDP-1,2880x1920,0x0,1"
    else
        hyprctl keyword monitor "eDP-1,disable"
    fi
fi