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

    // Track key/value pairs locally so Repeater can bind them
    property var keyList: []
    property var valueList: []

    function rebuildLists() {
        if (!behaviourObject) return
        var dict = behaviourObject.dict
        var keys = Object.keys(dict)
        keyList = keys
        valueList = keys.map(function(k) { return dict[k] })
    }

    Connections {
        target: behaviourObject
        function onDictChanged() { root.rebuildLists() }
    }

    onBehaviourObjectChanged: rebuildLists()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // ── Header ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Key"; font.pixelSize: 10; font.bold: true; color: ThemeManager.textColor; opacity: 0.6; Layout.preferredWidth: 90 }
            Text { text: "Value"; font.pixelSize: 10; font.bold: true; color: ThemeManager.textColor; opacity: 0.6; Layout.fillWidth: true }
            Item { width: 28 }
        }

        // ── Rows ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.03)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
            clip: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent.width
                    spacing: 3

                    Repeater {
                        model: root.keyList.length
                        delegate: RowLayout {
                            width: parent.width
                            spacing: 4
                            property string currentKey: root.keyList[index] || ""

                            CustomTextField {
                                Layout.fillWidth: false
                                Layout.preferredWidth: 88; Layout.preferredHeight: 28
                                text: root.keyList[index] || ""
                                font.pixelSize: 11
                                placeholderText: "key"
                                onEditingFinished: {
                                    if (behaviourObject && text !== currentKey) {
                                        behaviourObject.removeEntry(currentKey)
                                        if (text) behaviourObject.setEntry(text, root.valueList[index] || "")
                                    }
                                }
                            }
                            CustomTextField {
                                Layout.fillWidth: true; Layout.preferredHeight: 28
                                text: root.valueList[index] || ""
                                font.pixelSize: 11
                                placeholderText: "value"
                                onEditingFinished: if (behaviourObject) behaviourObject.setEntry(root.keyList[index], text)
                            }
                            Rectangle {
                                width: 24; height: 24; radius: 4
                                color: delMouse.containsMouse ? "#FF1744" : Qt.rgba(1, 0.1, 0.2, 0.15)
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 14; font.bold: true; color: "#FF5252" }
                                MouseArea {
                                    id: delMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if (behaviourObject) behaviourObject.removeEntry(root.keyList[index])
                                }
                            }
                        }
                    }

                    // ── Add row ───────────────────────────────────────────
                    Rectangle {
                        width: parent.width; height: 28; radius: 4
                        color: addMouse.containsMouse
                               ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15)
                               : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.06)
                        Behavior on color { ColorAnimation { duration: 100 } }
                        RowLayout {
                            anchors.centerIn: parent; spacing: 4
                            Text { text: "+"; font.pixelSize: 14; font.bold: true; color: ThemeManager.primaryColor }
                            Text { text: "Add entry"; font.pixelSize: 11; color: ThemeManager.primaryColor; opacity: 0.8 }
                        }
                        MouseArea {
                            id: addMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: if (behaviourObject) behaviourObject.setEntry("key" + (root.keyList.length + 1), "")
                        }
                    }
                }
            }
        }

        // ── Auto + Send ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Auto"; font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6; Layout.alignment: Qt.AlignVCenter }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoSend : false
                onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            NewButton {
                text: "Send"; variant: "filled"; iconSource: Icons.flash
                backgroundColor: ThemeManager.primaryColor
                Layout.preferredHeight: 28; Layout.preferredWidth: 70
                onClicked: if (behaviourObject) behaviourObject.send()
            }
        }
    }
}
