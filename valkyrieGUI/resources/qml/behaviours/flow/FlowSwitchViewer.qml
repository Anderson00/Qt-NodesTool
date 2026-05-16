import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    readonly property var caseColors: ["#2196F3","#9C27B0","#FF9800","#00BCD4","#607D8B"]
    readonly property var caseLabels: ["Case 0","Case 1","Case 2","Case 3","Default"]

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 5

        // Value display
        Rectangle {
            Layout.fillWidth: true; height: 36; radius: 6
            color: Qt.rgba(1, 0.6, 0, 0.08)
            border.width: 1; border.color: Qt.rgba(1, 0.6, 0, 0.3)
            RowLayout {
                anchors.fill: parent; anchors.margins: 8
                Text { text: "Value"; font.pixelSize: 11; color: ThemeManager.textSecondaryColor; Layout.fillWidth: true }
                Text {
                    text: behaviourObject ? behaviourObject.switchValue : "0"
                    font.pixelSize: 15; font.bold: true; font.family: "Consolas"; color: "#FF9800"
                }
            }
        }

        // Case indicators
        Repeater {
            model: 5
            delegate: Rectangle {
                Layout.fillWidth: true; height: 24; radius: 4
                property bool isActive: behaviourObject && (
                    (index < 4 && behaviourObject.lastCase === index) ||
                    (index === 4 && behaviourObject.lastCase === -1)
                )
                color: isActive ? Qt.rgba(
                    Qt.rgba(root.caseColors[index]).r,
                    Qt.rgba(root.caseColors[index]).g,
                    Qt.rgba(root.caseColors[index]).b, 0.2)
                    : Qt.rgba(0.5, 0.5, 0.5, 0.04)
                border.width: 1
                border.color: isActive ? root.caseColors[index] : Qt.rgba(0.5, 0.5, 0.5, 0.15)
                Behavior on color       { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "▶ " + root.caseLabels[index]
                    font.pixelSize: 10; font.bold: true
                    color: root.caseColors[index]
                    opacity: parent.isActive ? 1.0 : 0.45
                }
            }
        }

        // Value spinner
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 32
            label: "Set Value"
            value: behaviourObject ? behaviourObject.switchValue : 0
            from: 0; to: 100; stepSize: 1; decimals: 0; showBar: false
            accentColor: "#FF9800"
            onValueModified: function(v) { if (behaviourObject) behaviourObject.setValue(v) }
        }
    }
}
