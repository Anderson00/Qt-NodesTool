import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    readonly property var opNames:  ["+", "-", "×", "÷", "%", "xn"]
    readonly property var opColors: ["#2ecc71","#e74c3c","#3498db","#f39c12","#9b59b6","#1abc9c"]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // -- Operation selector ---------------------------------------------
        Rectangle {
            Layout.fillWidth: true; height: 30; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            clip: true

            Row {
                anchors.fill: parent; spacing: 0
                Repeater {
                    model: root.opNames
                    delegate: Rectangle {
                        width: parent.width / root.opNames.length; height: 30; radius: 4
                        color: behaviourObject && behaviourObject.operation === index
                               ? root.opColors[index] : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData; font.pixelSize: 14; font.bold: true
                            color: behaviourObject && behaviourObject.operation === index
                                   ? ThemeManager.backgroundColor : ThemeManager.textColor
                            opacity: behaviourObject && behaviourObject.operation === index ? 1.0 : 0.5
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: behaviourObject.setOperation(index)
                        }
                    }
                }
            }
        }

        // -- Result display -------------------------------------------------
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: behaviourObject ? behaviourObject.result.toFixed(4) : "0"
                    font.pixelSize: 18; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!behaviourObject) return ""
                        var a  = behaviourObject.valueA.toFixed(2)
                        var b  = behaviourObject.valueB.toFixed(2)
                        var op = root.opNames[behaviourObject.operation]
                        return a + " " + op + " " + b
                    }
                    font.pixelSize: 9; color: ThemeManager.textSecondaryColor
                }
            }
        }

        // -- A input --------------------------------------------------------
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 36
            label: "A"
            value: behaviourObject ? behaviourObject.valueA : 0
            from: -1e6; to: 1e6
            stepSize: 1.0; decimals: 2
            showBar: false
            accentColor: "#2ecc71"
            onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setA(newValue) }
        }

        // -- B input --------------------------------------------------------
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 36
            label: "B"
            value: behaviourObject ? behaviourObject.valueB : 0
            from: -1e6; to: 1e6
            stepSize: 1.0; decimals: 2
            showBar: false
            accentColor: "#3498db"
            onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setB(newValue) }
        }
    }
}

