import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import App.Theme 1.0
import App.Icons 1.0

Item {
    id: root

    property string title: qsTr("Drop files here")
    property string subtitle: qsTr("or click to browse")
    property var files: []
    property var nameFilters: ["All files (*)"]
    property bool multiple: true
    property color accentColor: ThemeManager.primaryColor
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.04)
    property color borderColor: Qt.rgba(1, 1, 1, 0.25)
    property int radius: 8

    signal filesDropped(var files)
    signal filesSelected(var files)

    implicitWidth: 320
    implicitHeight: 140

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: dropArea.containsDrag
               ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
               : root.backgroundColor

        Behavior on color { ColorAnimation { duration: 120 } }

        // Dashed border using a Canvas
        Canvas {
            id: dashed
            anchors.fill: parent
            property color strokeColor: dropArea.containsDrag
                                        ? root.accentColor : root.borderColor
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = strokeColor
                ctx.lineWidth = 1.5
                ctx.setLineDash([6, 4])
                ctx.beginPath()
                ctx.roundedRect ? ctx.roundedRect(1, 1, width - 2, height - 2, root.radius)
                                : ctx.rect(1, 1, width - 2, height - 2)
                ctx.stroke()
            }
            Connections {
                target: dropArea
                function onContainsDragChanged() { dashed.requestPaint() }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            SvgIcon {
                Layout.alignment: Qt.AlignHCenter
                width: 32; height: 32
                source: Icons.upload
                color: dropArea.containsDrag ? root.accentColor : ThemeManager.textColor
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.files.length > 0
                      ? qsTr("%1 file(s) selected").arg(root.files.length)
                      : root.title
                color: ThemeManager.textColor
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.subtitle
                color: Qt.rgba(1, 1, 1, 0.55)
                font.pixelSize: 11
            }
        }

        DropArea {
            id: dropArea
            anchors.fill: parent
            onDropped: function(drop) {
                if (drop.hasUrls) {
                    var paths = []
                    for (var i = 0; i < drop.urls.length; ++i)
                        paths.push(drop.urls[i].toString())
                    root.files = paths
                    root.filesDropped(paths)
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: dialog.open()
        }
    }

    FileDialog {
        id: dialog
        fileMode: root.multiple ? FileDialog.OpenFiles : FileDialog.OpenFile
        nameFilters: root.nameFilters
        onAccepted: {
            var paths = []
            if (root.multiple) {
                for (var i = 0; i < selectedFiles.length; ++i)
                    paths.push(selectedFiles[i].toString())
            } else {
                paths.push(selectedFile.toString())
            }
            root.files = paths
            root.filesSelected(paths)
        }
    }
}

