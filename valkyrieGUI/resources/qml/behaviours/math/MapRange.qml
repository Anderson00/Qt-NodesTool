import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    // Local preview when no C++ backend
    property real previewInput:  0.0
    property real previewInMin:  0.0
    property real previewInMax:  100.0
    property real previewOutMin: 0.0
    property real previewOutMax: 1.0
    property bool clampOut: true

    property real mappedValue: {
        var range = previewInMax - previewInMin
        if (Math.abs(range) < 1e-10) return previewOutMin
        var n = (previewInput - previewInMin) / range
        if (clampOut) n = Math.max(0, Math.min(1, n))
        return previewOutMin + n * (previewOutMax - previewOutMin)
    }

    property real normalizedIn: Math.max(0, Math.min(1,
        (previewInput - previewInMin) / Math.max(1e-10, previewInMax - previewInMin)))

    Connections {
        target: behaviourObject
        function onInputValueChanged()  { previewInput  = behaviourObject.inputValue }
        function onInMinChanged()       { previewInMin  = behaviourObject.inMin }
        function onInMaxChanged()       { previewInMax  = behaviourObject.inMax }
        function onOutMinChanged()      { previewOutMin = behaviourObject.outMin }
        function onOutMaxChanged()      { previewOutMax = behaviourObject.outMax }
        function onClampChanged()       { clampOut      = behaviourObject.clamp }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // -- Result display -------------------------------------------------
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 60; radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            ColumnLayout {
                anchors.centerIn: parent; spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.mappedValue.toFixed(6)
                    font.pixelSize: 20; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                    Behavior on text { }
                }

                // Progress bars: input position and output position
                Item {
                    width: 180; height: 16
                    anchors.horizontalCenter: parent.horizontalCenter

                    Column {
                        anchors.fill: parent; spacing: 3

                        Row {
                            spacing: 4
                            Text { text: "in";  font.pixelSize: 8; color: ThemeManager.textSecondaryColor; width: 12; verticalAlignment: Text.AlignVCenter; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                width: 156; height: 5; radius: 2
                                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
                                Rectangle {
                                    width: parent.width * root.normalizedIn; height: parent.height; radius: 2
                                    color: "#3498db"
                                    Behavior on width { NumberAnimation { duration: 100 } }
                                }
                            }
                        }

                        Row {
                            spacing: 4
                            property real normOut: {
                                var range = root.previewOutMax - root.previewOutMin
                                return Math.abs(range) < 1e-10 ? 0
                                    : Math.max(0, Math.min(1, (root.mappedValue - root.previewOutMin) / range))
                            }
                            Text { text: "out"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor; width: 12; verticalAlignment: Text.AlignVCenter; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                width: 156; height: 5; radius: 2
                                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
                                Rectangle {
                                    width: parent.width * parent.parent.normOut; height: parent.height; radius: 2
                                    color: ThemeManager.primaryColor
                                    Behavior on width { NumberAnimation { duration: 100 } }
                                }
                            }
                        }
                    }
                }
            }
        }

        // -- Formula display ------------------------------------------------
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "[" + previewInMin.toFixed(2) + ", " + previewInMax.toFixed(2) + "]  ?  [" +
                  previewOutMin.toFixed(2) + ", " + previewOutMax.toFixed(2) + "]"
            font.pixelSize: 10; font.family: "Consolas"
            color: ThemeManager.textSecondaryColor
        }

        // -- Input value ----------------------------------------------------
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 36
            label: "In"; value: root.previewInput
            from: -1e9; to: 1e9; stepSize: 1.0; decimals: 4
            showBar: true; accentColor: "#3498db"
            onValueModified: function(newValue) {
                root.previewInput = newValue
                if (behaviourObject) behaviourObject.setInputValue(newValue)
            }
        }

        // -- Input range ----------------------------------------------------
        Rectangle {
            Layout.fillWidth: true; implicitHeight: 1; color: ThemeManager.borderColor; opacity: 0.3
        }

        Text { text: "Input Range"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor }

        RowLayout {
            Layout.fillWidth: true; spacing: 4
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "Min"; value: root.previewInMin
                from: -1e9; to: 1e9; stepSize: 1; decimals: 4
                accentColor: "#3498db"
                onValueModified: function(newValue) { root.previewInMin = newValue; if (behaviourObject) behaviourObject.setInMin(newValue) }
            }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "Max"; value: root.previewInMax
                from: -1e9; to: 1e9; stepSize: 1; decimals: 4
                accentColor: "#3498db"
                onValueModified: function(newValue) { root.previewInMax = newValue; if (behaviourObject) behaviourObject.setInMax(newValue) }
            }
        }

        // -- Output range ---------------------------------------------------
        Text { text: "Output Range"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor }

        RowLayout {
            Layout.fillWidth: true; spacing: 4
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "Min"; value: root.previewOutMin
                from: -1e9; to: 1e9; stepSize: 0.1; decimals: 4
                accentColor: ThemeManager.primaryColor
                onValueModified: function(newValue) { root.previewOutMin = newValue; if (behaviourObject) behaviourObject.setOutMin(newValue) }
            }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "Max"; value: root.previewOutMax
                from: -1e9; to: 1e9; stepSize: 0.1; decimals: 4
                accentColor: ThemeManager.primaryColor
                onValueModified: function(newValue) { root.previewOutMax = newValue; if (behaviourObject) behaviourObject.setOutMax(newValue) }
            }
        }

        // -- Clamp toggle ---------------------------------------------------
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            CustomSwitch {
                checked: root.clampOut
                onCheckedChanged: { root.clampOut = checked; if (behaviourObject) behaviourObject.setClamp(checked) }
            }
            Text {
                text: "Clamp output to range"
                font.pixelSize: 10; color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}

