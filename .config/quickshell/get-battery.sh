#!/bin/bash
# Get battery percentage and status
CAPACITY=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo "0")
STATUS=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo "Unknown")

# Get time information using upower
BATTERY_INFO=$(upower -i $(upower -e | grep 'BAT') 2>/dev/null)
TIME_TO_FULL=$(echo "$BATTERY_INFO" | grep "time to full" | awk '{print $4 " " $5}' | head -1)
TIME_TO_EMPTY=$(echo "$BATTERY_INFO" | grep "time to empty" | awk '{print $4 " " $5}' | head -1)

# Determine which time to show based on status
if [[ "$STATUS" == "Charging" && -n "$TIME_TO_FULL" ]]; then
    TIME_INFO="$TIME_TO_FULL until full"
elif [[ "$STATUS" == "Discharging" && -n "$TIME_TO_EMPTY" ]]; then
    TIME_INFO="$TIME_TO_EMPTY remaining"
elif [[ "$STATUS" == "Not charging" && "$CAPACITY" == "100" ]]; then
    TIME_INFO="Fully charged"
    STATUS="Full"
else
    TIME_INFO="Time unknown"
fi

echo "${CAPACITY},${STATUS},${TIME_INFO}"
