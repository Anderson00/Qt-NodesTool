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

    property var    previewRows:    []
    property var    previewHeaders: []
    property string errorMsg:       ""

    Connections {
        target: behaviourObject
        function onInternalRowsRead(rows, headers) {
            previewRows    = rows.slice(0, 5)
            previewHeaders = headers
            errorMsg       = ""
        }
        function onInternalError(msg) {
            errorMsg    = msg
            previewRows = []
        }
        function onInternalClear() {
            previewRows    = []
            previewHeaders = []
            errorMsg       = ""
        }
        function onRowCountChanged()    { /* badge re-reads from behaviourObject */ }
        function onColumnCountChanged() { }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Title ─────────────────────────────────────────────────────────
        Text {
            text: "CSV Reader / Writer"
            color: ThemeManager.textColor
            font.pixelSize: 11
            font.bold: true
        }

        // ── File path row ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            CustomTextField {
                id: filePathField
                Layout.fillWidth: true
                placeholderText: "path/to/file.csv"
                text: behaviourObject ? behaviourObject.filePath : ""
            }
        }

        // ── Options row ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Delimiter:"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
                Layout.alignment: Qt.AlignVCenter
            }
            CustomTextField {
                id: delimField
                Layout.preferredWidth: 36
                text: behaviourObject ? behaviourObject.delimiter : ","
                onTextChanged: {
                    if (behaviourObject && text !== "")
                        behaviourObject.delimiter = text
                }
            }

            Item { width: 8 }

            Text {
                text: "Header:"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
                Layout.alignment: Qt.AlignVCenter
            }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.hasHeader : true
                onCheckedChanged: {
                    if (behaviourObject) behaviourObject.hasHeader = checked
                }
            }

            Item { Layout.fillWidth: true }

            // Badges
            Rectangle {
                visible: behaviourObject && behaviourObject.rowCount > 0
                width: rowBadge.implicitWidth + 14
                height: 18; radius: 9
                color: Qt.rgba(ThemeManager.primaryColor.r,
                               ThemeManager.primaryColor.g,
                               ThemeManager.primaryColor.b, 0.15)
                border.width: 1
                border.color: ThemeManager.primaryColor
                Text {
                    id: rowBadge
                    anchors.centerIn: parent
                    text: (behaviourObject ? behaviourObject.rowCount : 0) + "R"
                    color: ThemeManager.primaryColor
                    font.pixelSize: 8
                    font.bold: true
                }
            }
            Rectangle {
                visible: behaviourObject && behaviourObject.columnCount > 0
                width: colBadge.implicitWidth + 14
                height: 18; radius: 9
                color: Qt.rgba(ThemeManager.primaryColor.r,
                               ThemeManager.primaryColor.g,
                               ThemeManager.primaryColor.b, 0.15)
                border.width: 1
                border.color: ThemeManager.primaryColor
                Text {
                    id: colBadge
                    anchors.centerIn: parent
                    text: (behaviourObject ? behaviourObject.columnCount : 0) + "C"
                    color: ThemeManager.primaryColor
                    font.pixelSize: 8
                    font.bold: true
                }
            }
        }

        // ── Action buttons ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                variant: "filled"
                label: "Read"
                backgroundColor: ThemeManager.primaryColor
                onClicked: {
                    if (behaviourObject && filePathField.text.trim() !== "")
                        behaviourObject.readFile(filePathField.text.trim())
                }
            }
            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                variant: "outlined"
                label: "Write"
                onClicked: {
                    if (behaviourObject && filePathField.text.trim() !== "" && previewRows.length > 0)
                        behaviourObject.writeFile(filePathField.text.trim(), previewRows)
                }
            }
            NewButton {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 28
                variant: "outlined"
                label: "Clear"
                onClicked: { if (behaviourObject) behaviourObject.clear() }
            }
        }

        // ── Error ─────────────────────────────────────────────────────────
        Text {
            visible: errorMsg !== ""
            Layout.fillWidth: true
            text: errorMsg
            color: ThemeManager.errorColor
            font.pixelSize: 9
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // ── Preview (first 5 rows) ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                           ThemeManager.backgroundColor.g,
                           ThemeManager.backgroundColor.b, 0.4)
            radius: 3
            clip: true
            visible: previewRows.length > 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    height: 20
                    color: Qt.rgba(ThemeManager.surfaceColor.r,
                                   ThemeManager.surfaceColor.g,
                                   ThemeManager.surfaceColor.b, 0.9)
                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        Repeater {
                            model: previewHeaders
                            delegate: Text {
                                width: Math.max(50, (previewList.width - 4) / Math.max(1, previewHeaders.length))
                                height: 20
                                text: modelData
                                color: ThemeManager.textColor
                                font.pixelSize: 8
                                font.bold: true
                                elide: Text.ElideRight
                                leftPadding: 2
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                ListView {
                    id: previewList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: previewRows.length
                    delegate: Rectangle {
                        width: previewList.width
                        height: 18
                        color: index % 2 === 0 ? "transparent"
                                               : Qt.rgba(ThemeManager.textColor.r,
                                                         ThemeManager.textColor.g,
                                                         ThemeManager.textColor.b, 0.04)
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            Repeater {
                                model: previewHeaders
                                delegate: Text {
                                    width: Math.max(50, (previewList.width - 4) / Math.max(1, previewHeaders.length))
                                    height: 18
                                    text: {
                                        var row = previewRows[index]
                                        return row ? (row[modelData] !== undefined ? String(row[modelData]) : "") : ""
                                    }
                                    color: ThemeManager.textColor
                                    font.pixelSize: 8
                                    font.family: "Consolas, monospace"
                                    elide: Text.ElideRight
                                    leftPadding: 2
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
