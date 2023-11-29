#!/bin/zsh

bat=/sys/class/power_supply/BAT0/
per="$(cat "$bat/capacity")"
stat="$(cat "$bat/status")"

if [ "$per" -gt "90" ]; then
	icon=""
elif [ "$per" -gt "65" ]; then
	icon=""
elif [ "$per" -gt "40" ]; then
	icon=""
elif [ "$per" -gt "15" ]; then
	icon=""
else
	icon=""
fi

if [[ $stat == "Charging" ]]; then
	icon="$icon "
fi

if [ "$per" -gt "98" ]; then
	stage="full"
elif [ "$per" -gt "25" ]; then
	stage="ok"
else
	stage="critical"
fi



if [ -s /sys/class/power_supply/BAT0/capacity ]; then
    echo "{\"percent\": \"$per\", \"icon\": \"$icon\", \"charging\": \"$charging\", \"visible\": \"true\", \"status\": \"$stat\", \"stage\": \"$stage\"}"
else
    echo "{\"visible\": \"false\" }"
fi
