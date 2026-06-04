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

    // ── Local model é a fonte de verdade da UI ────────────────────────────
    // Não usamos Connections para dictChanged — evita rebuild e perda de foco.
    // Sincronizamos do C++ apenas no carregamento inicial.
    ListModel { id: pairsModel }

    function loadFromDict() {
        pairsModel.clear()
        if (!behaviourObject) return
        var d = behaviourObject.dict
        var keys = Object.keys(d)
        for (var i = 0; i < keys.length; i++)
            pairsModel.append({ pkey: keys[i], pval: d[keys[i]] })
    }

    onBehaviourObjectChanged: loadFromDict()
    Component.onCompleted:    loadFromDict()

    // Commit de edição de key: remove a key antiga, cria a nova
    function commitKey(index, oldKey, newKey) {
        if (oldKey === newKey) return
        var val = pairsModel.get(index).pval
        pairsModel.set(index, { pkey: newKey, pval: val })
        if (behaviourObject) {
            if (oldKey) behaviourObject.removeEntry(oldKey)
            if (newKey) behaviourObject.setEntry(newKey, val)
        }
    }

    // Commit de edição de value
    function commitVal(index, key, newVal) {
        pairsModel.set(index, { pkey: key, pval: newVal })
        if (behaviourObject && key) behaviourObject.setEntry(key, newVal)
    }

    // Adiciona nova entrada
    function addEntry() {
        var key = "key" + (pairsModel.count + 1)
        pairsModel.append({ pkey: key, pval: "" })
        if (behaviourObject) behaviourObject.setEntry(key, "")
    }

    // Remove entrada por índice
    function removeAt(index) {
        var key = pairsModel.get(index).pkey
        pairsModel.remove(index)
        if (behaviourObject && key) behaviourObject.removeEntry(key)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // ── Column headers ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Text { text: qsTr("Key");   font.pixelSize: 10; font.bold: true; color: ThemeManager.textColor; opacity: 0.55; Layout.preferredWidth: 90 }
            Text { text: qsTr("Value"); font.pixelSize: 10; font.bold: true; color: ThemeManager.textColor; opacity: 0.55; Layout.fillWidth: true }
            Item  { width: 30 }
        }

        // ── Rows (ListModel → delegates estáveis) ─────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.03)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
            clip: true

            ScrollView {
                id: dictScroll
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: availableWidth
                contentHeight: dictCol.implicitHeight
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                clip: true

                Column {
                    id: dictCol
                    width: dictScroll.availableWidth
                    spacing: 3

                    Repeater {
                        model: pairsModel
                        delegate: RowLayout {
                            id: rowItem
                            width: dictCol.width
                            spacing: 4

                            // Salva a key original ao iniciar edição
                            property string savedKey: pkey

                            CustomTextField {
                                Layout.fillWidth: false
                                Layout.preferredWidth: 86
                                Layout.preferredHeight: 30
                                text: pkey
                                placeholderText: "key"
                                onActiveFocusChanged: if (activeFocus) rowItem.savedKey = text
                                onEditingFinished:    root.commitKey(index, rowItem.savedKey, text)
                            }
                            CustomTextField {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                text: pval
                                placeholderText: "value"
                                onEditingFinished: root.commitVal(index, pkey, text)
                            }
                            Rectangle {
                                width: 26; height: 26; radius: 4
                                color: delMa.containsMouse ? "#FF1744" : Qt.rgba(1, 0.1, 0.2, 0.18)
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: qsTr("−"); font.pixelSize: 15; font.bold: true; color: "#FF5252" }
                                MouseArea {
                                    id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removeAt(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Add entry — sempre visível, fora do scroll ────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 5
            color: addMa.containsMouse
                   ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.18)
                   : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.07)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.25)
            Behavior on color { ColorAnimation { duration: 100 } }
            RowLayout {
                anchors.centerIn: parent; spacing: 5
                Text { text: qsTr("+"); font.pixelSize: 15; font.bold: true; color: ThemeManager.primaryColor }
                Text { text: qsTr("Add entry"); font.pixelSize: 12; color: ThemeManager.primaryColor }
            }
            MouseArea {
                id: addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: root.addEntry()
            }
        }

        // ── Auto toggle ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: qsTr("Auto-send"); font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6; Layout.alignment: Qt.AlignVCenter }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoSend : false
                onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ── Send — full width ─────────────────────────────────────────────
        NewButton {
            Layout.fillWidth: true; Layout.preferredHeight: 36
            text: qsTr("Send"); variant: "filled"; iconSource: Icons.flash
            backgroundColor: ThemeManager.primaryColor
            onClicked: if (behaviourObject) behaviourObject.send()
        }
    }
}
