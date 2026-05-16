import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 6

        // Waiting indicator
        Rectangle {
            Layout.fillWidth: true; height: 40; radius: 8
            color: behaviourObject && behaviourObject.isWaiting
                   ? Qt.rgba(1, 0.6, 0, 0.15) : Qt.rgba(0.5, 0.5, 0.5, 0.05)
            border.width: 1
            border.color: behaviourObject && behaviourObject.isWaiting ? "#FF9800" : Qt.rgba(0.5,0.5,0.5,0.2)
            Behavior on color       { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.centerIn: parent; spacing: 8
                // Spinner dot
                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: behaviourObject && behaviourObject.isWaiting ? "#FF9800" : ThemeManager.borderColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                    SequentialAnimation on opacity {
                        running: behaviourObject ? behaviourObject.isWaiting : false
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                    }
                }
                Text {
                    text: behaviourObject && behaviourObject.isWaiting ? "Waiting..." : "Ready"
                    font.pixelSize: 13; font.bold: true
                    color: behaviourObject && behaviourObject.isWaiting ? "#FF9800" : ThemeManager.textSecondaryColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Delay input
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 36
            label: "Delay (ms)"
            value: behaviourObject ? behaviourObject.delayMs : 1000
            from: 0; to: 60000; stepSize: 100; decimals: 0; showBar: false
            accentColor: "#FF9800"
            onValueModified: function(v) { if (behaviourObject) behaviourObject.setDelayMs(v) }
        }
    }
}
