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

    property int  localCurrent:  0
    property int  localMax:      10
    property bool localAutoFlush: true
    property var  recentValues:  []

    Connections {
        target: behaviourObject
        function onInternalCountChanged(current, max) {
            localCurrent = current
            localMax     = max
        }
        function onInternalFlushed(values) {
            // Keep last 5 items for preview
            var copy = []
            var start = Math.max(0, values.length - 5)
            for (var i = start; i < values.length; ++i)
                copy.push(values[i])
            root.recentValues = copy
            localCurrent = 0
        }
        function onBufferSizeChanged() {
            if (behaviourObject) localMax = behaviourObject.bufferSize
        }
        function onAutoFlushChanged() {
            if (behaviourObject) localAutoFlush = behaviourObject.autoFlush
        }
    }

    Component.onCompleted: {
        if (behaviourObject) {
            localMax      = behaviourObject.bufferSize
            localCurrent  = behaviourObject.currentCount
            localAutoFlush = behaviourObject.autoFlush
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // -- Header row --
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Buffer Accumulator")
                font.pixelSize: 10
                font.bold: true
                color: ThemeManager.textColor
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Badge {
                dotText: localCurrent + "/" + localMax
                badgeColor: localCurrent >= localMax
                       ? ThemeManager.errorColor
                       : ThemeManager.primaryColor
            }
        }

        // -- Buffer size spinner --
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Size")
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
            }

            NumberSpinBox {
                Layout.fillWidth: true
                value: localMax
                from: 1
                to: 10000
                onValueChanged: {
                    if (behaviourObject && value !== behaviourObject.bufferSize)
                        behaviourObject.setBufferSize(value)
                    localMax = value
                }
            }
        }

        // -- Fill progress bar --
        Rectangle {
            Layout.fillWidth: true
            height: 8
            radius: 4
            color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)

            Rectangle {
                width: localMax > 0
                       ? Math.min(1.0, localCurrent / localMax) * parent.width
                       : 0
                height: parent.height
                radius: parent.radius
                color: localCurrent >= localMax
                       ? ThemeManager.errorColor
                       : ThemeManager.primaryColor
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        // -- AutoFlush toggle --
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            CustomSwitch {
                checked: localAutoFlush
                onCheckedChanged: {
                    localAutoFlush = checked
                    if (behaviourObject) behaviourObject.setAutoFlush(checked)
                }
            }

            Text {
                text: qsTr("Auto-flush when full")
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // -- Recent values preview --
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.5)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.4)
            clip: true

            Column {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 2

                Text {
                    text: qsTr("Last flushed (max 5)")
                    font.pixelSize: 8
                    color: ThemeManager.textSecondaryColor
                }

                ListView {
                    id: recentList
                    width: parent.width
                    height: parent.height - 16
                    model: root.recentValues
                    clip: true
                    spacing: 1

                    delegate: Text {
                        width: recentList.width
                        text: qsTr("• ") + modelData
                        font.pixelSize: 9
                        font.family: "Consolas, monospace"
                        color: ThemeManager.textColor
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: recentList.count === 0
                        text: qsTr("No data yet")
                        font.pixelSize: 9
                        color: ThemeManager.textSecondaryColor
                    }
                }
            }
        }

        // -- Action buttons --
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                variant: "outlined"
                text: qsTr("Flush")
                onClicked: { if (behaviourObject) behaviourObject.flush() }
            }

            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                variant: "outlined"
                text: qsTr("Reset")
                onClicked: { if (behaviourObject) behaviourObject.reset() }
            }
        }
    }
}
