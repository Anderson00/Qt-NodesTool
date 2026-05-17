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

    // ── Change log (last 20 entries) ─────────────────────────────────────────
    ListModel { id: changeLog }

    Connections {
        target: behaviourObject

        function onInternalFileChanged(path, timestamp) {
            if (changeLog.count >= 20)
                changeLog.remove(0)
            changeLog.append({ "entry": timestamp + "  " + path })
        }

        function onInternalClear() {
            changeLog.clear()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Path row ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            CustomTextField {
                id: pathField
                Layout.fillWidth: true
                placeholderText: "File or directory path..."
                text: behaviourObject ? behaviourObject.watchedPath : ""
                onEditingFinished: behaviourObject.setPath(text)
            }

            Rectangle {
                width: 28; height: 28; radius: 4
                color: folderMouse.containsMouse
                    ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.18)
                    : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                border.color: ThemeManager.borderColor; border.width: 1

                SvgIcon {
                    anchors.centerIn: parent
                    source: Icons.folder
                    color: ThemeManager.textSecondaryColor
                    width: 16; height: 16
                }

                MouseArea {
                    id: folderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: behaviourObject.setPath(pathField.text)
                }
                AppToolTip { text: "Apply path"; visible: folderMouse.containsMouse; delay: 600 }
            }
        }

        // ── Control row ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            // Watch / Unwatch toggle
            NewButton {
                Layout.fillWidth: true
                text: behaviourObject && behaviourObject.isWatching ? "Unwatch" : "Watch"
                variant: behaviourObject && behaviourObject.isWatching ? "outlined" : "filled"
                onClicked: {
                    if (behaviourObject.isWatching)
                        behaviourObject.stop()
                    else
                        behaviourObject.start()
                }
            }

            // Read button
            NewButton {
                text: "Read"
                variant: "outlined"
                onClicked: behaviourObject.readFile()
            }

            // Clear log button
            NewButton {
                text: "Clear"
                variant: "outlined"
                onClicked: behaviourObject.internalClear()
            }

            // Change count badge
            Badge {
                text: behaviourObject ? behaviourObject.changeCount.toString() : "0"
                color: ThemeManager.primaryColor
            }
        }

        // ── Status row ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            StatusDot {
                active: behaviourObject ? behaviourObject.isWatching : false
            }

            Text {
                text: behaviourObject && behaviourObject.isWatching ? "Watching" : "Idle"
                color: behaviourObject && behaviourObject.isWatching
                    ? ThemeManager.successColor : ThemeManager.textSecondaryColor
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            Text {
                text: behaviourObject && behaviourObject.lastChange !== ""
                    ? behaviourObject.lastChange : "No changes yet"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
                elide: Text.ElideLeft
                Layout.maximumWidth: 160
            }
        }

        // ── Change log ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 4
            clip: true

            ListView {
                id: logView
                anchors.fill: parent
                anchors.margins: 4
                model: changeLog
                spacing: 1
                verticalLayoutDirection: ListView.BottomToTop

                delegate: Text {
                    width: logView.width
                    text: model.entry
                    color: ThemeManager.textSecondaryColor
                    font { pixelSize: 10; family: "Consolas" }
                    elide: Text.ElideLeft
                }
            }
        }
    }
}
