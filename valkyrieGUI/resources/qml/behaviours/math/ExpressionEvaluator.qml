import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // ── Expression input ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 32; radius: 5
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                           ThemeManager.textColor.b, 0.06)
            border.width: _exprIn.activeFocus ? 1 : 0
            border.color: ThemeManager.primaryColor

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 6; spacing: 4

                Text {
                    text: qsTr("f(x)"); font.pixelSize: 9; font.italic: true
                    color: ThemeManager.primaryColor; opacity: 0.8
                }

                TextInput {
                    id: _exprIn
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: "Consolas, Courier New, monospace"
                    font.pixelSize: 12; color: ThemeManager.textColor
                    clip: true; selectionColor: ThemeManager.primaryColor
                    text: behaviourObject ? (behaviourObject.expression || "a + b") : ""
                    onTextChanged: {
                        if (behaviourObject && behaviourObject.expression !== text)
                            behaviourObject.setExpression(text)
                    }
                }
            }
        }

        // ── Error display ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 20; radius: 4
            visible: behaviourObject && behaviourObject.hasError
            color: Qt.rgba(0.94, 0.27, 0.27, 0.12)
            border.color: "#EF4444"; border.width: 1

            Text {
                anchors { fill: parent; leftMargin: 6 }
                verticalAlignment: Text.AlignVCenter
                text: behaviourObject ? (behaviourObject.errorMsg || "") : ""
                font.pixelSize: 9; color: "#EF4444"; elide: Text.ElideRight
            }
        }

        // ── Result display ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 44; radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                           ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                  ThemeManager.primaryColor.b, 0.25)
            visible: !(behaviourObject && behaviourObject.hasError)

            Text {
                anchors.centerIn: parent
                text: behaviourObject ? behaviourObject.result.toFixed(6) : "0.000000"
                font.pixelSize: 16; font.family: "Consolas"; font.bold: true
                color: ThemeManager.primaryColor
            }
        }

        // ── Inputs a, b, c, d ─────────────────────────────────────────────────
        Repeater {
            model: [
                {lbl:"a", getter:"valueA", setter:"setA", color:"#2ecc71"},
                {lbl:"b", getter:"valueB", setter:"setB", color:"#3498db"},
                {lbl:"c", getter:"valueC", setter:"setC", color:"#f39c12"},
                {lbl:"d", getter:"valueD", setter:"setD", color:"#9b59b6"}
            ]
            delegate: NumericInputField {
                Layout.fillWidth: true; implicitHeight: 32
                label: modelData.lbl
                value: behaviourObject ? behaviourObject[modelData.getter] : 0
                from: -1e6; to: 1e6; stepSize: 0.1; decimals: 4
                showBar: false; accentColor: modelData.color
                onValueModified: function(v) {
                    if (behaviourObject) behaviourObject[modelData.setter](v)
                }
            }
        }
    }
}
