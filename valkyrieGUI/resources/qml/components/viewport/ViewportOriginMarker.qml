import QtQuick 2.12
import App.Theme 1.0

// Crosshair at world origin (0, 0).
// Position this item at x: 5000, y: 5000 inside the 10 000×10 000 workspace.
Item {
    z: -1

    // Horizontal arm
    Rectangle {
        width: 80; height: 1
        x: -width  / 2
        y: -height / 2
        color: ThemeManager.primaryColor
        opacity: 0.35
    }

    // Vertical arm
    Rectangle {
        width: 1; height: 80
        x: -width  / 2
        y: -height / 2
        color: ThemeManager.primaryColor
        opacity: 0.35
    }

    // Center dot
    Rectangle {
        width: 6; height: 6; radius: 3
        x: -width  / 2
        y: -height / 2
        color: ThemeManager.primaryColor
        opacity: 0.70
    }

    // Label
    Text {
        x: 7; y: -16
        text: "0, 0"
        font.pixelSize: 10
        color: ThemeManager.primaryColor
        opacity: 0.50
    }
}
