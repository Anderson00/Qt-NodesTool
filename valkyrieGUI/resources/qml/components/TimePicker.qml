import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// TimePicker — inline HH:MM:SS (or HH:MM) time picker with scroll drums.
//
// Usage:
//   TimePicker {
//       showSeconds: false
//       onTimeChanged: function(h, m, s) { console.log(h, m, s) }
//   }
Item {
    id: root

    property int  hours:       0
    property int  minutes:     0
    property int  seconds:     0
    property bool showSeconds: true
    property bool use24h:      true
    property color accentColor: ThemeManager.primaryColor
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color borderColor: Qt.rgba(1, 1, 1, 0.18)
    property int  radius:      6

    signal timeChanged(int hours, int minutes, int seconds)
    signal accepted(int hours, int minutes, int seconds)

    implicitWidth:  root.showSeconds ? 220 : 152
    implicitHeight: 140

    function _fmt2(n) { return n < 10 ? "0" + n : "" + n }

    // ── Drum component ────────────────────────────────────────────────────────
    component Drum: Item {
        id: drum
        property int  value:   0
        property int  minVal:  0
        property int  maxVal:  23
        property bool wrap:    true
        implicitWidth: 56; implicitHeight: root.height

        function _inc() {
            var nv = drum.value + 1
            if (drum.wrap && nv > drum.maxVal) nv = drum.minVal
            nv = Math.min(drum.maxVal, nv)
            drum.value = nv
        }
        function _dec() {
            var nv = drum.value - 1
            if (drum.wrap && nv < drum.minVal) nv = drum.maxVal
            nv = Math.max(drum.minVal, nv)
            drum.value = nv
        }

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.backgroundColor
            border.width: 1; border.color: root.borderColor

            // Up arrow
            Rectangle {
                width: parent.width; height: 36; radius: root.radius
                color: upArea.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: 10; color: ThemeManager.textSecondaryColor }
                MouseArea { id: upArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drum._inc() }
            }

            // Value display
            Text {
                anchors.centerIn: parent
                text: root._fmt2(drum.value)
                font.pixelSize: 26; font.bold: true; font.family: "Consolas"
                color: ThemeManager.textColor
            }

            // Accent underline
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: downArrow.top; anchors.bottomMargin: 8
                width: 24; height: 2; radius: 1
                color: root.accentColor; opacity: 0.7
            }

            // Down arrow
            Rectangle {
                id: downArrow
                anchors.bottom: parent.bottom
                width: parent.width; height: 36; radius: root.radius
                color: downArea.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: 10; color: ThemeManager.textSecondaryColor }
                MouseArea { id: downArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: drum._dec() }
            }
        }

        // Scroll wheel support
        WheelHandler {
            onWheel: function(event) {
                if (event.angleDelta.y > 0) drum._inc()
                else                        drum._dec()
            }
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing: 4

        Drum {
            Layout.fillWidth: true; implicitHeight: root.height
            value: root.hours
            minVal: 0; maxVal: root.use24h ? 23 : 11
            onValueChanged: function(v) { root.hours = v; root.timeChanged(root.hours, root.minutes, root.seconds) }
        }

        Text { text: ":"; font.pixelSize: 22; font.bold: true; color: ThemeManager.textColor; Layout.alignment: Qt.AlignVCenter }

        Drum {
            Layout.fillWidth: true; implicitHeight: root.height
            value: root.minutes
            minVal: 0; maxVal: 59
            onValueChanged: function(v) { root.minutes = v; root.timeChanged(root.hours, root.minutes, root.seconds) }
        }

        Text { visible: root.showSeconds; text: ":"; font.pixelSize: 22; font.bold: true; color: ThemeManager.textColor; Layout.alignment: Qt.AlignVCenter }

        Drum {
            visible: root.showSeconds
            Layout.fillWidth: root.showSeconds; implicitHeight: root.height
            value: root.seconds
            minVal: 0; maxVal: 59
            onValueChanged: function(v) { root.seconds = v; root.timeChanged(root.hours, root.minutes, root.seconds) }
        }
    }
}

