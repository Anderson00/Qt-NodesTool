import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// Avatar — circular avatar with image or initials fallback.
//
// Usage:
//   Avatar { name: "John Doe"; size: 40 }
//   Avatar { imageSource: "qrc:/img/user.png"; size: 48 }
Item {
    id: root

    property string imageSource: ""
    property string name:        ""         // used to generate initials
    property int    size:        36
    property int    fontSize:    size * 0.38
    property color  borderColor: "transparent"
    property int    borderWidth: 0
    property bool   showStatus:  false
    property string status:      "online"   // "online" | "offline" | "away" | "busy"

    implicitWidth:  root.size
    implicitHeight: root.size

    readonly property string _initials: {
        var s = root.name.trim()
        if (!s) return "?"
        var parts = s.split(" ")
        if (parts.length === 1) return parts[0][0].toUpperCase()
        return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
    }

    // Deterministic color from name
    readonly property color _bgColor: {
        var colors = ["#e74c3c","#e67e22","#f1c40f","#2ecc71","#1abc9c",
                      "#3498db","#9b59b6","#34495e","#e91e63","#00bcd4"]
        if (root.name === "") return ThemeManager.primaryColor
        var h = 0
        for (var i = 0; i < root.name.length; i++)
            h = (h * 31 + root.name.charCodeAt(i)) & 0xfffffff
        return colors[h % colors.length]
    }

    readonly property color _statusColor: {
        switch(root.status) {
            case "online":  return "#4caf50"
            case "away":    return "#ff9800"
            case "busy":    return "#f44336"
            default:        return "#9e9e9e"
        }
    }

    Rectangle {
        id: circle
        anchors.centerIn: parent
        width: root.size; height: root.size; radius: root.size / 2
        color: root.imageSource !== "" ? "transparent" : root._bgColor
        border.color: root.borderColor; border.width: root.borderWidth
        clip: true

        // Image
        Image {
            visible: root.imageSource !== ""
            anchors.fill: parent
            source: root.imageSource
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }

        // Initials fallback
        Text {
            visible: root.imageSource === ""
            anchors.centerIn: parent
            text: root._initials
            font.pixelSize: root.fontSize
            font.bold: true
            color: "#ffffff"
        }
    }

    // Status dot
    Rectangle {
        visible: root.showStatus
        width: root.size * 0.28; height: width; radius: width / 2
        anchors.right: circle.right; anchors.bottom: circle.bottom
        anchors.rightMargin: root.borderWidth; anchors.bottomMargin: root.borderWidth
        color: root._statusColor
        border.color: ThemeManager.backgroundColor; border.width: 2
    }
}

