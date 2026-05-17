import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property int  localPassed:   0
    property int  localDropped:  0
    property string localMode:   "throttle"
    property int  localInterval: 500

    // Activity flash state
    property bool flashPass:  false
    property bool flashDrop:  false

    Connections {
        target: behaviourObject
        function onInternalPassed(value) {
            localPassed = behaviourObject ? behaviourObject.passedCount : localPassed + 1
            root.flashPass = true
            flashPassTimer.restart()
        }
        function onInternalDropped() {
            localDropped = behaviourObject ? behaviourObject.droppedCount : localDropped + 1
            root.flashDrop = true
            flashDropTimer.restart()
        }
        function onModeChanged() {
            if (behaviourObject) localMode = behaviourObject.mode
        }
        function onIntervalMsChanged() {
            if (behaviourObject) localInterval = behaviourObject.intervalMs
        }
    }

    Timer { id: flashPassTimer; interval: 300; onTriggered: root.flashPass = false }
    Timer { id: flashDropTimer; interval: 300; onTriggered: root.flashDrop = false }

    Component.onCompleted: {
        if (behaviourObject) {
            localMode     = behaviourObject.mode
            localInterval = behaviourObject.intervalMs
            localPassed   = behaviourObject.passedCount
            localDropped  = behaviourObject.droppedCount
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // -- Header --
        Text {
            text: "Rate Limiter"
            font.pixelSize: 10
            font.bold: true
            color: ThemeManager.textColor
        }

        // -- Mode selector chips --
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Mode"
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
            }

            Chip {
                label: "Throttle"
                backgroundColor: localMode === "throttle"
                                 ? ThemeManager.primaryColor
                                 : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                textColor: localMode === "throttle"
                           ? "white"
                           : ThemeManager.textSecondaryColor
                onClicked: {
                    localMode = "throttle"
                    if (behaviourObject) behaviourObject.setMode("throttle")
                }
            }

            Chip {
                label: "Debounce"
                backgroundColor: localMode === "debounce"
                                 ? ThemeManager.primaryColor
                                 : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                textColor: localMode === "debounce"
                           ? "white"
                           : ThemeManager.textSecondaryColor
                onClicked: {
                    localMode = "debounce"
                    if (behaviourObject) behaviourObject.setMode("debounce")
                }
            }
        }

        // -- Interval spinner --
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Interval (ms)"
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 72
            }

            NumberSpinBox {
                Layout.fillWidth: true
                value: localInterval
                from: 10
                to: 60000
                stepSize: 50
                onValueChanged: {
                    localInterval = value
                    if (behaviourObject && value !== behaviourObject.intervalMs)
                        behaviourObject.setIntervalMs(value)
                }
            }
        }

        // -- Counters row --
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Activity indicator
            Rectangle {
                id: activityDot
                width: 10
                height: 10
                radius: 5
                color: root.flashPass ? "#2ecc71" : (root.flashDrop ? "#e74c3c" : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.4))
                Layout.alignment: Qt.AlignVCenter

                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                text: "Passed: " + localPassed
                font.pixelSize: 9
                color: "#2ecc71"
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "Dropped: " + localDropped
                font.pixelSize: 9
                color: "#e74c3c"
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            NewButton {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 22
                variant: "outlined"
                label: "Reset"
                onClicked: {
                    localPassed  = 0
                    localDropped = 0
                }
            }
        }

        // -- Mode description --
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.4)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)

            Text {
                anchors.fill: parent
                anchors.margins: 6
                wrapMode: Text.WordWrap
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                text: localMode === "throttle"
                      ? "Throttle: passes at most one value per interval. Excess values are dropped immediately."
                      : "Debounce: delays emission until no new value arrives within the interval. Resets the timer on each push."
            }
        }
    }
}
