import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

Item {
    id: root

    property date selectedDate: new Date()
    property color accentColor: ThemeManager.primaryColor
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color borderColor: Qt.rgba(1, 1, 1, 0.18)
    property string displayFormat: "yyyy-MM-dd"
    property int radius: 6

    signal dateChanged(date date)

    implicitWidth: 180
    implicitHeight: 36

    Rectangle {
        id: field
        anchors.fill: parent
        radius: root.radius
        color: root.backgroundColor
        border.width: 1
        border.color: popup.visible ? root.accentColor : root.borderColor
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(root.selectedDate, root.displayFormat)
                color: ThemeManager.textColor
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            // Calendar icon
            Rectangle {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                color: "transparent"
                border.width: 1.5
                border.color: ThemeManager.textColor
                radius: 2
                Rectangle {
                    width: parent.width; height: 3
                    color: ThemeManager.textColor
                    anchors.top: parent.top
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.open()
        }
    }

    Popup {
        id: popup
        y: root.height + 4
        width: 260
        padding: 8

        background: Rectangle {
            radius: root.radius
            color: ThemeManager.backgroundColor
            border.color: root.borderColor
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 6

            // Header: month / year navigation
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Button {
                    text: qsTr("<")
                    flat: true
                    Layout.preferredWidth: 28
                    onClicked: {
                        if (grid.month === 0) {
                            grid.month = 11
                            grid.year--
                        } else grid.month--
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: Qt.locale().standaloneMonthName(grid.month) + " " + grid.year
                    color: ThemeManager.textColor
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
                Button {
                    text: qsTr(">")
                    flat: true
                    Layout.preferredWidth: 28
                    onClicked: {
                        if (grid.month === 11) {
                            grid.month = 0
                            grid.year++
                        } else grid.month++
                    }
                }
            }

            // Day-of-week labels
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: ["S", "M", "T", "W", "T", "F", "S"]
                    Text {
                        Layout.fillWidth: true
                        text: modelData
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Day grid
            Grid {
                id: grid
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 2

                property int month: root.selectedDate.getMonth()
                property int year: root.selectedDate.getFullYear()
                readonly property int firstDay: new Date(year, month, 1).getDay()
                readonly property int daysInMonth: new Date(year, month + 1, 0).getDate()

                Repeater {
                    model: 42
                    Rectangle {
                        property int dayNum: index - grid.firstDay + 1
                        property bool inMonth: dayNum >= 1 && dayNum <= grid.daysInMonth
                        property bool isSelected: inMonth &&
                            dayNum === root.selectedDate.getDate() &&
                            grid.month === root.selectedDate.getMonth() &&
                            grid.year === root.selectedDate.getFullYear()

                        width: (grid.width - 6 * grid.columnSpacing) / 7
                        height: width
                        radius: width / 2
                        color: isSelected ? root.accentColor
                             : (mouseArea.containsMouse && inMonth
                                ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: inMonth ? dayNum : ""
                            color: isSelected ? "#ffffff" : ThemeManager.textColor
                            font.pixelSize: 12
                            opacity: inMonth ? 1.0 : 0.0
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: parent.inMonth
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedDate = new Date(grid.year, grid.month, parent.dayNum)
                                root.dateChanged(root.selectedDate)
                                popup.close()
                            }
                        }
                    }
                }
            }
        }
    }
}

