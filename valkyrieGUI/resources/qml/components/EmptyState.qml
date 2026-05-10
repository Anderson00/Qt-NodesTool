import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// EmptyState — friendly placeholder for empty lists / zero-data screens.
//
// Usage:
//   EmptyState {
//       icon: "📂"
//       title: "No files yet"
//       subtitle: "Drop a file or click Browse to get started"
//       actionLabel: "Browse"
//       onActionClicked: fileDialog.open()
//   }
Item {
    id: root

    property string icon:        "○"
    property string iconSource:  ""    // optional SVG/image; overrides icon text
    property int    iconSize:    48
    property string title:       qsTr("Nothing here")
    property string subtitle:    ""
    property string actionLabel: ""
    property color  accentColor: ThemeManager.primaryColor
    property int    spacing:     12

    signal actionClicked()

    implicitWidth:  280
    implicitHeight: col.implicitHeight + 32

    Column {
        id: col
        anchors.centerIn: parent
        spacing: root.spacing
        width: root.width

        // Icon
        Item {
            width: parent.width; height: root.iconSize
            Image {
                visible: root.iconSource !== ""
                anchors.centerIn: parent
                source: root.iconSource
                width: root.iconSize; height: root.iconSize
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: 0.45
            }
            Text {
                visible: root.iconSource === ""
                anchors.centerIn: parent
                text: root.icon
                font.pixelSize: root.iconSize
                color: Qt.rgba(ThemeManager.textColor.r,
                               ThemeManager.textColor.g,
                               ThemeManager.textColor.b, 0.3)
            }
        }

        // Title
        Text {
            width: parent.width
            text: root.title
            font.pixelSize: 16; font.bold: true
            color: Qt.rgba(ThemeManager.textColor.r,
                           ThemeManager.textColor.g,
                           ThemeManager.textColor.b, 0.7)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        // Subtitle
        Text {
            visible: root.subtitle !== ""
            width: parent.width
            text: root.subtitle
            font.pixelSize: 13
            color: Qt.rgba(ThemeManager.textColor.r,
                           ThemeManager.textColor.g,
                           ThemeManager.textColor.b, 0.45)
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }

        // Action button
        Item {
            visible: root.actionLabel !== ""
            width: parent.width; height: 36

            Rectangle {
                anchors.centerIn: parent
                height: 34; radius: 6
                width: actionText.width + 32
                color: root.accentColor
                opacity: actionMa.containsMouse ? 0.9 : 1.0

                Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: root.actionLabel
                    font.pixelSize: 13; font.bold: true
                    color: "#ffffff"
                }

                MouseArea {
                    id: actionMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.actionClicked()
                }
            }
        }
    }
}
