import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Ctrl
import App.Theme 1.0
import App.Variables 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 6

        // ── Variable selector ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 30; radius: 5
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                           ThemeManager.textColor.b, 0.06)
            border.color: ThemeManager.primaryColor
            border.width: _combo.activeFocus ? 1 : 0

            Ctrl.ComboBox {
                id: _combo
                anchors.fill: parent
                textRole: "name"
                model: VariableManager.variables
                background: Item {}
                contentItem: Text {
                    leftPadding: 8
                    text: behaviourObject && behaviourObject.selectedName
                          ? behaviourObject.selectedName : "— select variable —"
                    font.pixelSize: 11; color: ThemeManager.textColor
                    verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
                }
                popup: Ctrl.Popup {
                    width: _combo.width; y: _combo.height; padding: 0
                    Ctrl.ScrollView {
                        width: parent.width
                        height: Math.min(200, _wList.contentHeight)
                        ListView {
                            id: _wList
                            model: VariableManager.variables
                            delegate: Rectangle {
                                width: _combo.width; height: 28
                                color: _wma.containsMouse
                                       ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                                 ThemeManager.primaryColor.b, 0.12)
                                       : ThemeManager.backgroundColor
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 10; spacing: 6
                                    Text { text: modelData.type; font.pixelSize: 9
                                           color: ThemeManager.primaryColor; opacity: 0.7 }
                                    Text { Layout.fillWidth: true; text: modelData.name
                                           font.pixelSize: 11; color: ThemeManager.textColor
                                           elide: Text.ElideRight }
                                    // Lock indicator
                                    Text { visible: !modelData.readOnly; text: "\u2713"
                                           font.pixelSize: 9; color: "#10B981" }
                                    Text { visible: modelData.readOnly; text: "\uD83D\uDD12"
                                           font.pixelSize: 9; color: "#EF4444" }
                                }
                                MouseArea {
                                    id: _wma; anchors.fill: parent; hoverEnabled: true
                                    onClicked: {
                                        if (!modelData.readOnly) {
                                            behaviourObject.setSelectedId(modelData.id)
                                            _combo.popup.close()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Last written value ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true; radius: 6
            color: Qt.rgba(0.94, 0.27, 0.27, 0.06)
            border.width: 1; border.color: Qt.rgba(0.94, 0.27, 0.27, 0.2)

            Column {
                anchors.centerIn: parent; spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\u21A7 writing"
                    font.pixelSize: 9; color: ThemeManager.textSecondaryColor; opacity: 0.5
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: behaviourObject ? (behaviourObject.lastValue || "—") : "—"
                    font.pixelSize: 13; font.family: "Consolas"; font.bold: true
                    color: "#EF4444"; elide: Text.ElideRight
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: behaviourObject ? (behaviourObject.currentType || "") : ""
                    font.pixelSize: 9; color: ThemeManager.textSecondaryColor; opacity: 0.5
                }
            }
        }
    }
}
