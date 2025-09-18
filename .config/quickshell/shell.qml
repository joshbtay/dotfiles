import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls

ShellRoot {
    property int currentWorkspace: 3
    property int batteryPercentage: 25
    property string batteryStatus: "Charging"
    property string batteryTimeInfo: "1.1 hours until full"
    property real cpuUsage: 6.3
    property int memoryUsage: 3
    property int temperature: 43
    
    // Get battery info using file-based approach
    Process {
        id: batteryUpdater
        command: ["/home/josh/.config/quickshell/get-battery.sh"]
        
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                // Now try to read the files directly
                percentReader.running = true
            }
        }
    }
    
    Process {
        id: percentReader
        command: ["cat", "/tmp/quickshell-battery-percent"]
        
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && stdout && stdout.trim()) {
                batteryPercentage = parseInt(stdout.trim()) || 0
                console.log("Battery percent:", batteryPercentage)
                // Now get status
                statusReader.running = true
            }
        }
    }
    
    Process {
        id: statusReader
        command: ["cat", "/tmp/quickshell-battery-status"]
        
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && stdout && stdout.trim()) {
                batteryStatus = stdout.trim() || "Unknown"
                console.log("Battery status:", batteryStatus)
                // Now get time info
                timeReader.running = true
            }
        }
    }
    
    Process {
        id: timeReader
        command: ["cat", "/tmp/quickshell-battery-time"]
        
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && stdout && stdout.trim()) {
                batteryTimeInfo = stdout.trim() || "Time unknown"
                console.log("Battery time:", batteryTimeInfo)
            }
        }
    }
    
    // System info processes
    Process {
        id: systemUpdater
        command: ["/home/josh/.config/quickshell/get-system-info.sh"]
        
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0) {
                cpuReader.running = true
            }
        }
    }
    
    Process {
        id: cpuReader
        command: ["cat", "/tmp/quickshell-cpu"]
        
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && stdout && stdout.trim()) {
                cpuUsage = parseFloat(stdout.trim()) || 0
                memoryReader.running = true
            }
        }
    }
    
    Process {
        id: memoryReader
        command: ["cat", "/tmp/quickshell-memory"]
        
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && stdout && stdout.trim()) {
                memoryUsage = parseInt(stdout.trim()) || 0
                tempReader.running = true
            }
        }
    }
    
    Process {
        id: tempReader
        command: ["cat", "/tmp/quickshell-temperature"]
        
        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && stdout && stdout.trim()) {
                temperature = parseInt(stdout.trim()) || 0
            }
        }
    }
    
    Timer {
        interval: 10000  // Update every 10 seconds
        running: true
        repeat: true
        onTriggered: {
            batteryUpdater.running = true
            systemUpdater.running = true
        }
    }
    
    Component.onCompleted: {
        // Initial checks
        batteryUpdater.running = true
        systemUpdater.running = true
    }
    
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            property var modelData
            screen: modelData
            
            anchors {
                left: true
                right: true
                top: true
            }
            
            implicitHeight: 42
            color: "transparent"
            
            // Background with blur effect
            Rectangle {
                anchors.fill: parent
                color: "#1a1a1a"
                opacity: 0.85
                
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                
                // Left modules
                RowLayout {
                    Layout.fillHeight: true
                    spacing: 4
                    
                    // Workspaces
                    RowLayout {
                        spacing: 6
                        
                        Repeater {
                            model: 10
                            
                            Rectangle {
                                Layout.preferredHeight: 26
                                Layout.preferredWidth: 36
                                color: (index + 1) === currentWorkspace ? "#555555" : "#2a2a2a"
                                radius: 8
                                border.width: (index + 1) === currentWorkspace ? 0 : 1
                                border.color: "#404040"
                                
                                // Subtle shadow for active workspace
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -2
                                    color: "transparent"
                                    border.color: (index + 1) === currentWorkspace ? "#55555540" : "transparent"
                                    border.width: 2
                                    radius: parent.radius + 2
                                    z: -1
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: (index + 1).toString()
                                    color: (index + 1) === currentWorkspace ? "white" : "#aaaaaa"
                                    font.family: "SF Pro Display, Roboto, sans-serif"
                                    font.pixelSize: 12
                                    font.weight: (index + 1) === currentWorkspace ? Font.Medium : Font.Normal
                                }
                                
                                Process {
                                    id: workspaceProcess
                                    command: ["hyprctl", "dispatch", "workspace", "1"]
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        workspaceProcess.command = ["hyprctl", "dispatch", "workspace", (index + 1).toString()]
                                        workspaceProcess.running = true
                                    }
                                    hoverEnabled: true
                                    
                                    onEntered: parent.color = (index + 1) === currentWorkspace ? "#666666" : "#3a3a3a"
                                    onExited: parent.color = (index + 1) === currentWorkspace ? "#555555" : "#2a2a2a"
                                }
                            }
                        }
                    }
                }
                
                // Center modules  
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width * 0.8, windowTitle.implicitWidth + 24)
                        height: 26
                        color: "#2a2a2a"
                        radius: 13
                        border.width: 1
                        border.color: "#404040"
                        
                        Text {
                            id: windowTitle
                            anchors.centerIn: parent
                            text: "Active Window Title"
                            color: "#e0e0e0"
                            font.family: "SF Pro Display, Roboto, sans-serif"
                            font.pixelSize: 12
                            font.weight: Font.Normal
                            elide: Text.ElideMiddle
                            maximumLineCount: 1
                        }
                    }
                }
                
                // Right modules
                RowLayout {
                    Layout.fillHeight: true
                    spacing: 4
                    
                    // System info group
                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: systemInfo.implicitWidth + 16
                        color: "#2a2a2a"
                        radius: 13
                        border.width: 1
                        border.color: "#404040"
                        
                        RowLayout {
                            id: systemInfo
                            anchors.centerIn: parent
                            spacing: 12
                            
                            Text {
                                text: "CPU " + cpuUsage.toFixed(1) + "%"
                                color: {
                                    if (cpuUsage >= 80) return "#e74c3c"  // red
                                    else if (cpuUsage >= 60) return "#f39c12"  // yellow
                                    else return "white"  // normal
                                }
                                font.family: "SF Pro Display, Roboto, sans-serif"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                            
                            Rectangle {
                                width: 1
                                height: 12
                                color: "#404040"
                            }
                            
                            Text {
                                text: "RAM " + memoryUsage + "%"
                                color: {
                                    if (memoryUsage >= 80) return "#e74c3c"  // red
                                    else if (memoryUsage >= 60) return "#f39c12"  // yellow
                                    else return "white"  // normal
                                }
                                font.family: "SF Pro Display, Roboto, sans-serif"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                            
                            Rectangle {
                                width: 1
                                height: 12
                                color: "#404040"
                            }
                            
                            Text {
                                text: temperature + "°C"
                                color: {
                                    if (temperature >= 85) return "#e74c3c"  // red
                                    else if (temperature >= 75) return "#f39c12"  // yellow
                                    else return "white"  // normal
                                }
                                font.family: "SF Pro Display, Roboto, sans-serif"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }
                    
                    // Audio
                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 70
                        color: "#2a2a2a"
                        radius: 13
                        border.width: 1
                        border.color: "#404040"
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            
                            Text {
                                text: "󰕾"
                                color: "#27ae60"
                                font.family: "Nerd Font"
                                font.pixelSize: 12
                            }
                            
                            Text {
                                text: "75%"
                                color: "#e0e0e0"
                                font.family: "SF Pro Display, Roboto, sans-serif"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                        
                        Process {
                            id: pavucontrolProcess
                            command: ["pavucontrol"]
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: pavucontrolProcess.running = true
                            hoverEnabled: true
                            onEntered: parent.color = "#3a3a3a"
                            onExited: parent.color = "#2a2a2a"
                        }
                    }
                    
                    // Network
                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 80
                        color: "#2a2a2a"
                        radius: 13
                        border.width: 1
                        border.color: "#404040"
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            
                            Text {
                                text: "󰤨"
                                color: "#3498db"
                                font.family: "Nerd Font"
                                font.pixelSize: 12
                            }
                            
                            Text {
                                text: "WiFi"
                                color: "#e0e0e0"
                                font.family: "SF Pro Display, Roboto, sans-serif"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }
                    
                    // Battery
                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 70
                        color: "#2a2a2a"
                        radius: 13
                        border.width: 1
                        border.color: "#404040"
                        
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            
                            Text {
                                text: {
                                    if (batteryStatus === "Charging") return "󰂄"  // charging icon
                                    else if (batteryPercentage >= 90) return "󰁹"  // full
                                    else if (batteryPercentage >= 75) return "󰂂"  // 75%
                                    else if (batteryPercentage >= 50) return "󰂀"  // 50%
                                    else if (batteryPercentage >= 25) return "󰁾"  // 25%
                                    else return "󰁺"  // low/critical
                                }
                                color: {
                                    if (batteryStatus === "Charging") return "#f39c12"  // orange when charging
                                    else if (batteryPercentage >= 25) return "#2ecc71"  // green when good
                                    else return "#e74c3c"  // red when low
                                }
                                font.family: "Nerd Font"
                                font.pixelSize: 13
                            }
                            
                            Text {
                                text: batteryPercentage + "%"
                                color: "#e0e0e0"
                                font.family: "SF Pro Display, Roboto, sans-serif"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            
                            onEntered: batteryTooltip.visible = true
                            onExited: batteryTooltip.visible = false
                        }
                        
                        ToolTip {
                            id: batteryTooltip
                            text: batteryTimeInfo
                            visible: false
                            delay: 300
                            timeout: 5000
                            
                            background: Rectangle {
                                color: "#1a1a1a"
                                border.color: "#555555"
                                border.width: 1
                                radius: 6
                                
                                // Subtle shadow effect
                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -2
                                    color: "transparent"
                                    border.color: "#00000040"
                                    border.width: 1
                                    radius: parent.radius + 2
                                    z: -1
                                }
                            }
                            
                            contentItem: Text {
                                text: batteryTooltip.text
                                color: "#ffffff"
                                font.family: "SF Pro Display, Roboto, sans-serif"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 12
                                rightPadding: 12
                                topPadding: 8
                                bottomPadding: 8
                            }
                        }
                    }
                    
                    // Clock
                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 90
                        color: "#404040"
                        radius: 13

                        ClockWidget {
                            anchors.centerIn: parent
                            timeFormat: "hh:mm AP"
                            dateFormat: "ddd, MMM d"
                            font.family: "SF Pro Display, Roboto, sans-serif"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: "#e0e0e0"
                        }
                    }
                    
                    // System Tray
                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 26
                        color: "#2a2a2a"
                        radius: 13
                        border.width: 1
                        border.color: "#404040"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰍉"
                            color: "#95a5a6"
                            font.family: "Nerd Font"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
