import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// RangeSlider — dual-handle slider for selecting a min/max range.
// Signals: firstValueChanged(real), secondValueChanged(real)
//
// Usage:
//   RangeSlider {
//       from: 0; to: 100
//       firstValue: 20; secondValue: 80
//       onFirstValueChanged: console.log("min =", firstValue)
//       onSecondValueChanged: console.log("max =", secondValue)
//   }
Item {
    id: root

    property real from:         0
    property real to:           100
    property real firstValue:   0
    property real secondValue:  100
    property real stepSize:     0          // 0 = continuous
    property int  decimals:     0
    property bool showLabels:   true
    property bool showValues:   true
    property color accentColor: ThemeManager.primaryColor
    property color trackColor:  Qt.rgba(ThemeManager.textColor.r,
                                        ThemeManager.textColor.g,
                                        ThemeManager.textColor.b, 0.15)
    property int   trackHeight: 4
    property int   handleSize:  18
    property string label:      ""

    signal rangeChanged(real first, real second)

    implicitWidth:  200
    implicitHeight: showLabels && label !== "" ? 58 : (showValues ? 46 : 28)

    // ── Helpers ──────────────────────────────────────────────────────────────
    function _snap(v) {
        if (root.stepSize <= 0) return v
        return Math.round((v - root.from) / root.stepSize) * root.stepSize + root.from
    }
    function _clamp(v) { return Math.max(root.from, Math.min(root.to, v)) }
    function _norm(v)  { return (v - root.from) / Math.max(1e-9, root.to - root.from) }
    function _fmt(v)   { return v.toFixed(root.decimals) }

    // ── Label ─────────────────────────────────────────────────────────────────
    Text {
        id: labelText
        visible: root.label !== ""
        text: root.label
        font.pixelSize: 10; font.bold: true
        color: ThemeManager.textSecondaryColor
        anchors.top: parent.top
        anchors.left: parent.left
    }

    // ── Track container ───────────────────────────────────────────────────────
    Item {
        id: trackContainer
        anchors.top: labelText.visible ? labelText.bottom : parent.top
        anchors.topMargin: labelText.visible ? 4 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.handleSize + (root.showValues ? 18 : 0)

        // Track background
        Rectangle {
            id: trackBg
            anchors.verticalCenter: handle1.verticalCenter
            x: root.handleSize / 2
            width: parent.width - root.handleSize
            height: root.trackHeight
            radius: root.trackHeight / 2
            color: root.trackColor
        }

        // Active range fill
        Rectangle {
            anchors.verticalCenter: handle1.verticalCenter
            x: handle1.x + root.handleSize / 2
            width: handle2.x - handle1.x
            height: root.trackHeight
            radius: root.trackHeight / 2
            color: root.accentColor
            opacity: 0.85
        }

        // Handle 1 (first/min)
        Rectangle {
            id: handle1
            width: root.handleSize; height: root.handleSize; radius: root.handleSize / 2
            y: root.showValues ? 18 : 0
            x: root._norm(root.firstValue) * (trackBg.width) + trackBg.x - root.handleSize / 2
            color: root.accentColor
            border.width: 2; border.color: "#ffffff"
            z: drag1.active ? 2 : 1

            Behavior on color { ColorAnimation { duration: 120 } }

            // Value label above handle
            Text {
                visible: root.showValues
                text: root._fmt(root.firstValue)
                font.pixelSize: 9; font.bold: true
                color: root.accentColor
                anchors.bottom: parent.top; anchors.bottomMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            MouseArea {
                id: drag1
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.SizeHorCursor

                onPositionChanged: function(mouse) {
                    // Map to trackContainer coords so the moving handle doesn't skew the delta
                    var absX = drag1.mapToItem(trackContainer, mouse.x, 0).x
                    var norm = Math.max(0.0, Math.min(1.0,
                                   (absX - root.handleSize / 2) / Math.max(1, trackBg.width)))
                    var raw = root._snap(root.from + norm * (root.to - root.from))
                    var nv  = root.stepSize > 0
                              ? Math.min(root._clamp(raw), root.secondValue - root.stepSize)
                              : Math.min(root._clamp(raw), root.secondValue)
                    root.firstValue = nv
                    root.rangeChanged(root.firstValue, root.secondValue)
                }
            }
        }

        // Handle 2 (second/max)
        Rectangle {
            id: handle2
            width: root.handleSize; height: root.handleSize; radius: root.handleSize / 2
            y: root.showValues ? 18 : 0
            x: root._norm(root.secondValue) * (trackBg.width) + trackBg.x - root.handleSize / 2
            color: root.accentColor
            border.width: 2; border.color: "#ffffff"
            z: drag2.active ? 2 : 1

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                visible: root.showValues
                text: root._fmt(root.secondValue)
                font.pixelSize: 9; font.bold: true
                color: root.accentColor
                anchors.bottom: parent.top; anchors.bottomMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            MouseArea {
                id: drag2
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.SizeHorCursor

                onPositionChanged: function(mouse) {
                    var absX = drag2.mapToItem(trackContainer, mouse.x, 0).x
                    var norm = Math.max(0.0, Math.min(1.0,
                                   (absX - root.handleSize / 2) / Math.max(1, trackBg.width)))
                    var raw = root._snap(root.from + norm * (root.to - root.from))
                    var nv  = root.stepSize > 0
                              ? Math.max(root._clamp(raw), root.firstValue + root.stepSize)
                              : Math.max(root._clamp(raw), root.firstValue)
                    root.secondValue = nv
                    root.rangeChanged(root.firstValue, root.secondValue)
                }
            }
        }
    }
}

