import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property var    resultRows:    []
    property var    resultHeaders: []
    property string errorMsg:      ""
    property int    rowsCount:     0

    Connections {
        target: behaviourObject
        function onInternalRowsFetched(rows, headers) {
            resultRows    = rows
            resultHeaders = headers
            rowsCount     = rows.length
            errorMsg      = ""
        }
        function onInternalError(msg) {
            errorMsg  = msg
            resultRows = []
            rowsCount  = 0
        }
        function onIsConnectedChanged() {
            connectIndicator.requestPaint()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "SQLite Query"
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }

                // Connection indicator
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: behaviourObject && behaviourObject.isConnected ? "#2ecc71" : "#e74c3c"
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: behaviourObject && behaviourObject.isConnected ? "Connected" : "No DB"
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // ── DB Path ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.topMargin: 4
                anchors.bottomMargin: 4
                spacing: 4

                CustomTextField {
                    id: dbPathField
                    Layout.fillWidth: true
                    placeholderText: "database.db path..."
                    text: behaviourObject ? behaviourObject.dbPath : ""
                }
                NewButton {
                    Layout.preferredWidth: 52
                    Layout.fillHeight: true
                    variant: "filled"
                    label: "Open"
                    backgroundColor: ThemeManager.primaryColor
                    onClicked: {
                        if (behaviourObject && dbPathField.text.trim() !== "")
                            behaviourObject.setDatabase(dbPathField.text.trim())
                    }
                }
            }
        }

        // ── SQL Editor ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 70
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                           ThemeManager.backgroundColor.g,
                           ThemeManager.backgroundColor.b, 0.5)
            border.width: sqlArea.activeFocus ? 1 : 0
            border.color: ThemeManager.primaryColor
            radius: 3
            clip: true

            Flickable {
                id: sqlFlick
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: width
                contentHeight: sqlArea.contentHeight
                clip: true

                TextArea {
                    id: sqlArea
                    width: sqlFlick.width
                    wrapMode: TextArea.Wrap
                    font.family: "Consolas, monospace"
                    font.pixelSize: 11
                    color: ThemeManager.textColor
                    background: null
                    placeholderText: "SELECT * FROM table_name LIMIT 100;"
                    placeholderTextColor: ThemeManager.textSecondaryColor
                    selectByMouse: true
                }
            }
        }

        // ── Execute controls ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            height: 32
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            spacing: 6

            NewButton {
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                variant: "filled"
                label: "Execute"
                backgroundColor: ThemeManager.primaryColor
                enabled: behaviourObject && behaviourObject.isConnected
                onClicked: {
                    if (behaviourObject && sqlArea.text.trim() !== "")
                        behaviourObject.execute(sqlArea.text.trim())
                }
            }

            Rectangle {
                visible: rowsCount > 0
                width: rowsLabel.implicitWidth + 16
                height: 22
                radius: 11
                color: Qt.rgba(ThemeManager.primaryColor.r,
                               ThemeManager.primaryColor.g,
                               ThemeManager.primaryColor.b, 0.15)
                border.width: 1
                border.color: ThemeManager.primaryColor

                Text {
                    id: rowsLabel
                    anchors.centerIn: parent
                    text: rowsCount + " rows"
                    color: ThemeManager.primaryColor
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            Item { Layout.fillWidth: true }
        }

        // ── Error text ────────────────────────────────────────────────────
        Text {
            visible: errorMsg !== ""
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            text: errorMsg
            color: ThemeManager.errorColor
            font.pixelSize: 9
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // ── Result table ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                           ThemeManager.backgroundColor.g,
                           ThemeManager.backgroundColor.b, 0.4)
            clip: true
            visible: resultRows.length > 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header row
                Rectangle {
                    Layout.fillWidth: true
                    height: 22
                    color: Qt.rgba(ThemeManager.surfaceColor.r,
                                   ThemeManager.surfaceColor.g,
                                   ThemeManager.surfaceColor.b, 0.9)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        spacing: 0

                        Repeater {
                            model: resultHeaders
                            delegate: Text {
                                width: Math.max(60, (tableView.width - 4) / Math.max(1, resultHeaders.length))
                                height: 22
                                text: modelData
                                color: ThemeManager.textColor
                                font.pixelSize: 9
                                font.bold: true
                                elide: Text.ElideRight
                                leftPadding: 4
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                // Data rows
                ListView {
                    id: tableView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: Math.min(50, resultRows.length)

                    delegate: Rectangle {
                        width: tableView.width
                        height: 20
                        color: index % 2 === 0 ? "transparent"
                                               : Qt.rgba(ThemeManager.textColor.r,
                                                         ThemeManager.textColor.g,
                                                         ThemeManager.textColor.b, 0.04)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            spacing: 0

                            Repeater {
                                model: resultHeaders
                                delegate: Text {
                                    width: Math.max(60, (tableView.width - 4) / Math.max(1, resultHeaders.length))
                                    height: 20
                                    text: {
                                        var row = resultRows[index]
                                        return row ? (row[modelData] !== undefined ? String(row[modelData]) : "") : ""
                                    }
                                    color: ThemeManager.textColor
                                    font.pixelSize: 9
                                    font.family: "Consolas, monospace"
                                    elide: Text.ElideRight
                                    leftPadding: 4
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
