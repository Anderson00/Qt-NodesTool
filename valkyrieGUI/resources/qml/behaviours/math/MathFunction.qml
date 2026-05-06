import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    readonly property var funcNames: ["sin","cos","tan","abs","√","ln","log₁₀","eˣ","⌊x⌋","⌈x⌉","round"]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Function selector ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; implicitHeight: funcGrid.height + 8; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            clip: true

            Flow {
                id: funcGrid
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }
                spacing: 2

                Repeater {
                    model: root.funcNames
                    delegate: Rectangle {
                        width: 42; height: 22; radius: 3
                        color: behaviourObject && behaviourObject.function === index
                               ? ThemeManager.primaryColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData; font.pixelSize: 9
                            color: behaviourObject && behaviourObject.function === index
                                   ? ThemeManager.backgroundColor : ThemeManager.textColor
                            opacity: behaviourObject && behaviourObject.function === index ? 1.0 : 0.5
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: behaviourObject.setFunction(index)
                        }
                    }
                }
            }
        }

        // ── Result display ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 46; radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: behaviourObject ? behaviourObject.result.toFixed(6) : "0"
                    font.pixelSize: 16; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!behaviourObject) return ""
                        return root.funcNames[behaviourObject.function] + "(" + behaviourObject.inputValue.toFixed(2) + ")"
                    }
                    font.pixelSize: 9; color: ThemeManager.textSecondaryColor
                }
            }
        }

        // ── Input slider ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            Text { text: "x"; font.pixelSize: 10; color: ThemeManager.textSecondaryColor; Layout.preferredWidth: 16 }
            CustomSlider {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                from: -100; to: 100
                value: behaviourObject ? behaviourObject.inputValue : 0
                textColor: ThemeManager.textColor; color: ThemeManager.primaryColor
                onMoved: if(behaviourObject) behaviourObject.setInput(value)
            }
        }
    }
}
