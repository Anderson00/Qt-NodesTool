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

    ListModel { id: captureGroupsModel }

    Connections {
        target: behaviourObject

        function onInternalMatch(groups, matchCount) {
            captureGroupsModel.clear()
            for (var i = 0; i < groups.length; i++) {
                captureGroupsModel.append({ "groupIndex": i, "groupText": groups[i] })
            }
        }

        function onInternalNoMatch() {
            captureGroupsModel.clear()
        }

        function onInternalReplaced(result) {
            replaceResultField.text = result
        }

        function onInternalPatternError(error) {
            // error shown via lastError property binding
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Pattern field ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.6)
            border.color: behaviourObject && behaviourObject.lastError !== ""
                ? ThemeManager.errorColor
                : ThemeManager.borderColor
            border.width: 1
            radius: 6

            CustomTextField {
                anchors.fill: parent
                background: null
                placeholderText: "Regular expression pattern..."
                text: behaviourObject ? behaviourObject.pattern : ""
                onEditingFinished: behaviourObject.setPattern(text)
            }
        }

        // ── Error text ────────────────────────────────────────────────────────
        Text {
            Layout.fillWidth: true
            text: behaviourObject ? behaviourObject.lastError : ""
            color: ThemeManager.errorColor
            font.pixelSize: 9
            visible: behaviourObject && behaviourObject.lastError !== ""
            wrapMode: Text.WordWrap
        }

        // ── Flags row ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "Case insensitive"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 11
            }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.caseInsensitive : false
                onToggled: behaviourObject.setCaseInsensitive(checked)
            }

            Text {
                text: "Multi-line"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 11
            }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.multiLine : false
                onToggled: behaviourObject.setMultiLine(checked)
            }
        }

        // ── Text input area ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 6
            clip: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 4

                TextArea {
                    id: textInputArea
                    placeholderText: "Input text to match..."
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    background: null
                    wrapMode: TextArea.Wrap
                    onTextChanged: behaviourObject.setText(text)
                }
            }
        }

        // ── Replace row ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            CustomTextField {
                id: replaceInputField
                Layout.fillWidth: true
                placeholderText: "Replacement string..."
            }

            NewButton {
                text: "Replace"
                variant: "outlined"
                onClicked: behaviourObject.replace(replaceInputField.text)
            }
        }

        // ── Replace result ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 6
            clip: true

            TextInput {
                id: replaceResultField
                anchors.fill: parent
                anchors.margins: 5
                verticalAlignment: TextInput.AlignVCenter
                color: ThemeManager.textColor
                font { pixelSize: 10; family: "Consolas" }
                readOnly: true
                selectByMouse: true
                clip: true
            }
        }

        // ── Match count + capture groups ──────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Matches:"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 11
            }

            Badge {
                text: behaviourObject ? behaviourObject.matchCount.toString() : "0"
                color: behaviourObject && behaviourObject.matchCount > 0
                    ? ThemeManager.successColor : ThemeManager.textSecondaryColor
            }

            Item { Layout.fillWidth: true }
        }

        // ── Capture groups list ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 4
            clip: true
            visible: captureGroupsModel.count > 0

            ListView {
                id: groupsView
                anchors.fill: parent
                anchors.margins: 4
                model: captureGroupsModel
                spacing: 2

                delegate: RowLayout {
                    width: groupsView.width
                    spacing: 6

                    Text {
                        text: "[" + model.groupIndex + "]"
                        color: ThemeManager.primaryColor
                        font { pixelSize: 10; family: "Consolas" }
                        Layout.minimumWidth: 28
                    }

                    Text {
                        text: model.groupText
                        color: ThemeManager.textColor
                        font { pixelSize: 10; family: "Consolas" }
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
