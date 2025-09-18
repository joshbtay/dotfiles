#!/bin/bash
hyprctl activeworkspace | grep -o 'workspace ID [0-9]*' | grep -o '[0-9]*' > /tmp/quickshell-workspace