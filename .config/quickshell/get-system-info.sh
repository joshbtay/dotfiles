#!/bin/bash

# Get CPU usage (average over 1 second)
CPU_PERCENT=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')

# Get Memory usage
MEMORY_INFO=$(free | grep '^Mem:')
TOTAL_MEM=$(echo $MEMORY_INFO | awk '{print $2}')
USED_MEM=$(echo $MEMORY_INFO | awk '{print $3}')
MEM_PERCENT=$((USED_MEM * 100 / TOTAL_MEM))

# Get Temperature (try different sources)
TEMP=""
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP=$((TEMP_RAW / 1000))
elif command -v sensors >/dev/null 2>&1; then
    TEMP=$(sensors | grep -E 'Core 0|CPU' | head -1 | grep -o '[0-9]*°C' | head -1 | sed 's/°C//')
fi

# Default to 45 if we can't read temperature
if [ -z "$TEMP" ]; then
    TEMP=45
fi

# Output to separate files
echo "$CPU_PERCENT" > /tmp/quickshell-cpu
echo "$MEM_PERCENT" > /tmp/quickshell-memory
echo "$TEMP" > /tmp/quickshell-temperature
echo "${CPU_PERCENT},${MEM_PERCENT},${TEMP}" > /tmp/quickshell-system-info