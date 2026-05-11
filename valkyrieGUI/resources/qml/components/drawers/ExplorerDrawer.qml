import QtQuick 2.15
import QtQuick.Controls 2.15 as Contrl
import QtQuick.Layouts 1.14
import Qt.labs.folderlistmodel 2.15
import App.Theme 1.0
import App.Icons 1.0
import ".."

Item {
    id: root

    property var rootFolder:    "file:///"

    property var breadcrumbUrls:   [rootFolder]
    property var breadcrumbLabels: ["Root"]

    property string extensionFilter: "json"

    signal fileActivated(string filePath)

    // Re-init after parent sets rootFolder
    Component.onCompleted: {
        var url = root.rootFolder.toString()
        root.breadcrumbUrls   = [url]
        root.breadcrumbLabels = ["Root"]
        folderModel.folder    = url
    }

    function _navigate(folderUrl, label) {
        var urlStr = folderUrl.toString()
        root.breadcrumbUrls   = root.breadcrumbUrls.concat([urlStr])
        root.breadcrumbLabels = root.breadcrumbLabels.concat([label])
        folderModel.folder    = urlStr
    }

    function _navigateTo(index) {
        var newUrls   = root.breadcrumbUrls.slice(0, index + 1)
        var newLabels = root.breadcrumbLabels.slice(0, index + 1)
        root.breadcrumbUrls   = newUrls
        root.breadcrumbLabels = newLabels
        folderModel.folder    = newUrls[index].toString()
    }

    function _goBack() {
        if (root.breadcrumbUrls.length > 1)
            _navigateTo(root.breadcrumbUrls.length - 2)
    }

    FolderListModel {
        id: folderModel
        showDirs:  true
        showFiles: true
        showHidden: false
        showDotAndDotDot: false
        caseSensitive: false
        nameFilters: {
            if (root.extensionFilter)
                return ["*." + root.extensionFilter]
            var q = searchInput.text
            if (q) return ["*" + q + "*"]
            return []
        }
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Header ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 38
            color: Qt.darker(ThemeManager.backgroundColor, 1.15)

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.15
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6

                // Back button
                Item {
                    width: 24; height: 24
                    opacity: root.breadcrumbUrls.length > 1 ? 1.0 : 0.25
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    ColorIcon {
                        source: Icons.arrowLeft
                        color: ThemeManager.textColor
                        width: 14; height: 14; anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.breadcrumbUrls.length > 1
                        onClicked: root._goBack()
                    }
                }

                ColorIcon {
                    source: Icons.magnify
                    color: ThemeManager.textColor; opacity: 0.4
                    width: 14; height: 14
                }

                // Search field
                Rectangle {
                    Layout.fillWidth: true; height: 26; radius: 4
                    color: Qt.rgba(ThemeManager.textColor.r,
                                   ThemeManager.textColor.g,
                                   ThemeManager.textColor.b, 0.06)
                    border.width: searchInput.activeFocus ? 1 : 0
                    border.color: ThemeManager.primaryColor

                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.right: parent.right; anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search files…"; font.pixelSize: 12
                        color: ThemeManager.textColor; opacity: 0.3
                        visible: !searchInput.text.length && !searchInput.activeFocus
                    }
                    TextInput {
                        id: searchInput
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.right: parent.right; anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        height: 22
                        color: ThemeManager.textColor; font.pixelSize: 12; clip: true
                        selectionColor: ThemeManager.primaryColor
                        verticalAlignment: TextInput.AlignVCenter
                    }
                    Rectangle {
                        id: clearBtn
                        visible: searchInput.text.length > 0
                        width: 15; height: 15; radius: 8
                        anchors.right: parent.right; anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(ThemeManager.textColor.r,
                                       ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.2)
                        ColorIcon {
                            source: Icons.close
                            color: ThemeManager.textColor
                            width: 9; height: 9; anchors.centerIn: parent
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }
        }

        // ── Extension filter chips ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 30; color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.08
            }

            Row {
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Repeater {
                    model: ["all", "json", "txt"]
                    delegate: Rectangle {
                        property bool active: modelData === "all"
                                              ? root.extensionFilter === ""
                                              : root.extensionFilter === modelData
                        height: 18; width: chipTxt.implicitWidth + 14; radius: 9
                        color: active
                               ? ThemeManager.primaryColor
                               : Qt.rgba(ThemeManager.primaryColor.r,
                                         ThemeManager.primaryColor.g,
                                         ThemeManager.primaryColor.b, 0.12)
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: chipTxt; anchors.centerIn: parent
                            text: modelData === "all" ? "All" : ("." + modelData)
                            font.pixelSize: 10
                            color: active ? ThemeManager.backgroundColor : ThemeManager.textColor
                            opacity: active ? 1.0 : 0.6
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.extensionFilter = modelData === "all" ? "" : modelData
                        }
                    }
                }
            }
        }

        // ── Breadcrumb ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 28; clip: true; color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.1
            }

            Row {
                id: crumbRow
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0; height: 20

                Repeater {
                    model: root.breadcrumbLabels

                    delegate: Row {
                        height: 20; spacing: 0

                        Item {
                            width: Math.max(crumbHomeIco.implicitWidth,
                                            crumbTxt.implicitWidth) + 10
                            height: 20

                            ColorIcon {
                                id: crumbHomeIco
                                visible: index === 0
                                source: Icons.home
                                width: 12; height: 12; anchors.centerIn: parent
                                color: index === root.breadcrumbLabels.length - 1
                                       ? ThemeManager.textColor : ThemeManager.primaryColor
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            Text {
                                id: crumbTxt
                                visible: index > 0
                                text: modelData; font.pixelSize: 10
                                anchors.centerIn: parent
                                color: index === root.breadcrumbLabels.length - 1
                                       ? ThemeManager.textColor : ThemeManager.primaryColor
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: index < root.breadcrumbLabels.length - 1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root._navigateTo(index)
                            }
                        }

                        Text {
                            visible: index < root.breadcrumbLabels.length - 1
                            text: " › "; font.pixelSize: 10
                            color: ThemeManager.textColor; opacity: 0.35
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // ── File list ────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true

            Column {
                anchors.centerIn: parent; spacing: 10
                visible: folderModel.count === 0

                ColorIcon {
                    source: Icons.folderOpenOutline
                    color: ThemeManager.textColor; opacity: 0.18
                    width: 28; height: 28; anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "No files found"
                    font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.3
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            ListView {
                id: fileList
                anchors.fill: parent; clip: true

                Contrl.ScrollBar.vertical: Contrl.ScrollBar {
                    contentItem: Rectangle {
                        implicitWidth: 3; radius: 1.5
                        color: ThemeManager.primaryColor; opacity: 0.4
                    }
                }

                model: folderModel

                delegate: Rectangle {
                    width: fileList.width; height: 34
                    color: rowMouse.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r,
                                     ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.08)
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        height: 1; color: ThemeManager.primaryColor; opacity: 0.06
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 8

                        ColorIcon {
                            source: fileIsDir
                                    ? Icons.folderOutline
                                    : root._fileIcon(fileName)
                            color: fileIsDir ? "#F59E0B" : ThemeManager.textColor
                            opacity: fileIsDir ? 1.0 : 0.6
                            width: 15; height: 15
                        }

                        Text {
                            Layout.fillWidth: true
                            text: fileName; font.pixelSize: 12
                            color: ThemeManager.textColor; elide: Text.ElideMiddle
                        }

                        Text {
                            visible: !fileIsDir
                            text: root._sizeStr(fileSize)
                            font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.35
                        }

                        ColorIcon {
                            visible: fileIsDir
                            source: Icons.chevronRight
                            color: ThemeManager.textColor; opacity: 0.3
                            width: 12; height: 12
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked:       { if (fileIsDir)  root._navigate(fileUrl, fileName) }
                        onDoubleClicked: { if (!fileIsDir) root.fileActivated(filePath) }
                    }
                }
            }
        }
    }

    function _fileIcon(name) {
        var ext = name.split('.').pop().toLowerCase()
        if (ext === "json") return Icons.codeJson
        if (ext === "txt")  return Icons.fileDocumentOutline
        if (ext === "vky")  return Icons.graphOutline
        return Icons.fileOutline
    }

    function _sizeStr(bytes) {
        if (bytes < 1024)    return bytes + " B"
        if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB"
        return (bytes / 1048576).toFixed(1) + " MB"
    }
}

