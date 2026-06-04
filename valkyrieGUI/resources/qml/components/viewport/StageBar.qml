import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// Compact pill-shaped HUD shown during Presentation Mode when the workspace
// has saved stages. Lets the user jump between stages with the arrow buttons
// or the keyboard shortcuts (F5 / Shift+F5).
Rectangle {
    id: root

    property int    stageCount:   0
    property int    currentStage: 0
    property string stageName:    ""

    signal previousRequested()
    signal nextRequested()

    height: 48
    radius: 24
    color: Qt.rgba(0, 0, 0, 0.7)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.15)

    // Auto width based on content, capped at 400px so very long stage names
    // get elided instead of stretching the bar across the screen.
    width: Math.min(stageRow.implicitWidth + 40, 400)

    Row {
        id: stageRow
        anchors.centerIn: parent
        spacing: 12

        // ── Previous arrow ───────────────────────────────────────────────
        Text {
            text: "‹"   // ‹
            color: root.currentStage > 0 ? "white" : Qt.rgba(1, 1, 1, 0.3)
            font.pixelSize: 22
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.previousRequested()
            }
        }

        // ── Stage dots (≤ 8 stages) ──────────────────────────────────────
        Row {
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: root.stageCount > 0 && root.stageCount <= 8

            Repeater {
                model: root.stageCount
                Rectangle {
                    width:  index === root.currentStage ? 10 : 6
                    height: index === root.currentStage ? 10 : 6
                    radius: width / 2
                    color:  index === root.currentStage
                                ? ThemeManager.primaryColor
                                : Qt.rgba(1, 1, 1, 0.35)
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on width  { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on color  { ColorAnimation  { duration: 180 } }
                }
            }
        }

        // ── Numeric counter (> 8 stages) ─────────────────────────────────
        Text {
            visible: root.stageCount > 8
            text: (root.currentStage + 1) + " / " + root.stageCount
            color: "white"
            font.pixelSize: 12
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Stage name ───────────────────────────────────────────────────
        Text {
            text:           root.stageName
            color:          Qt.rgba(1, 1, 1, 0.85)
            font.pixelSize: 12
            maximumLineCount: 1
            elide:          Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }

        // ── Next arrow ───────────────────────────────────────────────────
        Text {
            text: "›"   // ›
            color: root.currentStage < root.stageCount - 1 ? "white"
                                                           : Qt.rgba(1, 1, 1, 0.3)
            font.pixelSize: 22
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.nextRequested()
            }
        }
    }
}
