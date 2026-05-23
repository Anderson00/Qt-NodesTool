import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

TextField {
    id: control

    implicitHeight: 34
    leftPadding:  8
    rightPadding: 8
    topPadding:   0
    bottomPadding: 0

    Layout.fillWidth: true

    font.pixelSize: 12
    font.family: "Segoe UI"

    color: ThemeManager.textColor
    placeholderTextColor: Qt.rgba(ThemeManager.textColor.r,
                                  ThemeManager.textColor.g,
                                  ThemeManager.textColor.b, 0.35)
    selectionColor:     Qt.rgba(ThemeManager.primaryColor.r,
                                ThemeManager.primaryColor.g,
                                ThemeManager.primaryColor.b, 0.4)
    selectedTextColor: ThemeManager.textColor

    background: Rectangle {
        color: control.activeFocus
               ? Qt.rgba(ThemeManager.primaryColor.r,
                         ThemeManager.primaryColor.g,
                         ThemeManager.primaryColor.b, 0.08)
               : Qt.rgba(ThemeManager.textColor.r,
                         ThemeManager.textColor.g,
                         ThemeManager.textColor.b, 0.06)
        border.color: control.activeFocus
                      ? ThemeManager.primaryColor
                      : Qt.rgba(ThemeManager.borderColor.r,
                                ThemeManager.borderColor.g,
                                ThemeManager.borderColor.b, 0.35)
        border.width: 1
        radius: 4
        Behavior on color        { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }
    }
}
