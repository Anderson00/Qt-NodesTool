import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1 as Platform
import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    // ── State ─────────────────────────────────────────────────────────────────
    property string selectedEventId: ""
    property var    selectedEvent:   null
    property bool   showCalendar:    false

    readonly property var triggerTypes: ["Intervalo","Data/Hora","Cron","Multi-Data"]
    readonly property var repeatModes:  ["Uma vez","Diário","Semanal"]

    function refreshSelected() {
        if (!behaviourObject || selectedEventId === "") { selectedEvent = null; return }
        selectedEvent = behaviourObject.getEvent(selectedEventId)
    }

    Connections {
        target: behaviourObject
        function onEventsChanged() { root.refreshSelected() }
    }

    // ── Layout: left list + right editor ──────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // ══════════════ LEFT — Event List ═════════════════════════════════════
        Rectangle {
            Layout.preferredWidth: 148
            Layout.fillHeight: true
            color: Qt.rgba(0,0,0,0.25)
            border.width: 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Eventos"
                        color: ThemeManager.textSecondaryColor
                        font.pixelSize: 10; font.bold: true
                        Layout.fillWidth: true
                    }
                    Text {
                        text: behaviourObject ? behaviourObject.eventCount + "" : "0"
                        color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                    }
                }

                // List
                ListView {
                    id: eventList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: behaviourObject ? behaviourObject.events : []

                    delegate: Rectangle {
                        width: eventList.width
                        height: 44
                        radius: 5
                        color: modelData.id === root.selectedEventId
                            ? Qt.rgba(1,1,1,0.1)
                            : (itemArea.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 5

                            // Enabled dot
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: modelData.enabled ? "#22C55E" : Qt.rgba(1,1,1,0.2)
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: ThemeManager.textColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: root.triggerTypes[modelData.triggerType] || "?"
                                    color: ThemeManager.textSecondaryColor
                                    font.pixelSize: 9
                                }
                            }

                            // Delete
                            Rectangle {
                                width: 18; height: 18; radius: 4
                                color: delA.containsMouse ? Qt.rgba(239,68,68,0.3) : "transparent"
                                visible: itemArea.containsMouse || delA.containsMouse
                                Text { anchors.centerIn: parent; text: "✕"; color: "#EF4444"; font.pixelSize: 9 }
                                MouseArea {
                                    id: delA; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.id === root.selectedEventId) {
                                            root.selectedEventId = ""
                                            root.selectedEvent = null
                                        }
                                        behaviourObject.removeEvent(modelData.id)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemArea; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedEventId = modelData.id
                                root.refreshSelected()
                            }
                        }
                    }
                }

                // Add button
                Rectangle {
                    Layout.fillWidth: true; height: 28; radius: 6
                    color: addA.containsMouse
                        ? Qt.lighter(ThemeManager.primaryColor, 1.2) : ThemeManager.primaryColor
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "+ Evento"; color: "#fff"; font.pixelSize: 11; font.bold: true }
                    MouseArea {
                        id: addA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var newId = behaviourObject.addEvent()
                            root.selectedEventId = newId
                            root.refreshSelected()
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle { width: 1; Layout.fillHeight: true; color: Qt.rgba(1,1,1,0.08) }

        // ══════════════ RIGHT — Event Editor ══════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"

            // Empty state
            Item {
                anchors.fill: parent
                visible: root.selectedEvent === null
                Text {
                    anchors.centerIn: parent
                    text: "Selecione ou crie\num evento →"
                    color: Qt.rgba(1,1,1,0.25); font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Editor (only visible when an event is selected)
            ScrollView {
                anchors.fill: parent
                visible: root.selectedEvent !== null
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent.width - 2
                    anchors.margins: 10
                    spacing: 8

                    // ── Name ──────────────────────────────────────────────────
                    Rectangle {
                        Layout.fillWidth: true; height: 34; radius: 6
                        color: Qt.rgba(1,1,1,0.05)
                        border.width: 1; border.color: nameField.activeFocus ? ThemeManager.primaryColor : Qt.rgba(1,1,1,0.12)
                        TextInput {
                            id: nameField
                            anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                            verticalAlignment: TextInput.AlignVCenter
                            text: root.selectedEvent ? root.selectedEvent.name : ""
                            color: ThemeManager.textColor; font.pixelSize: 13; font.bold: true
                            selectByMouse: true
                            onEditingFinished: if (root.selectedEventId !== "")
                                behaviourObject.updateEventField(root.selectedEventId, "name", text)
                        }
                    }

                    // ── Enabled toggle ────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        CustomSwitch {
                            id: enabledSwitch
                            text: "Evento ativo"
                            checked: root.selectedEvent ? root.selectedEvent.enabled : false
                            onCheckedChanged: if (root.selectedEventId !== "")
                                behaviourObject.updateEventField(root.selectedEventId, "enabled", checked)
                        }
                        Item { Layout.fillWidth: true }
                        // Run count
                        Text {
                            text: root.selectedEvent ? ("×" + root.selectedEvent.runCount) : ""
                            color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

                    // ── Trigger type ──────────────────────────────────────────
                    Text { text: "TIPO DE TRIGGER"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }

                    CustomComboBox {
                        id: triggerCombo
                        Layout.fillWidth: true
                        model: root.triggerTypes
                        currentIndex: root.selectedEvent ? root.selectedEvent.triggerType : 0
                        onCurrentIndexChanged: if (root.selectedEventId !== "")
                            behaviourObject.updateEventField(root.selectedEventId, "triggerType", currentIndex)
                    }

                    // ── Interval fields ───────────────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        visible: root.selectedEvent && root.selectedEvent.triggerType === 0

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Repeater {
                                model: [
                                    {lbl:"Dias",  fld:"days"},
                                    {lbl:"Horas", fld:"hours"},
                                    {lbl:"Min",   fld:"minutes"},
                                    {lbl:"Seg",   fld:"seconds"}
                                ]
                                ColumnLayout {
                                    spacing: 2
                                    Text { text: modelData.lbl; color: ThemeManager.textSecondaryColor; font.pixelSize: 9; Layout.alignment: Qt.AlignHCenter }
                                    VerticalSpinBox {
                                        from: 0; to: 999
                                        value: root.selectedEvent ? root.selectedEvent[modelData.fld] : 0
                                        onValueModified: function(newValue) {
                                            if (root.selectedEventId !== "") {
                                                behaviourObject.updateEventField(root.selectedEventId, modelData.fld, newValue)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Cron field ────────────────────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        visible: root.selectedEvent && root.selectedEvent.triggerType === 2

                        Rectangle {
                            Layout.fillWidth: true; height: 34; radius: 6
                            color: Qt.rgba(1,1,1,0.05)
                            border.width: 1; border.color: Qt.rgba(1,1,1,0.12)
                            TextInput {
                                id: cronInput
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.selectedEvent ? root.selectedEvent.cronExpression : "0 * * * *"
                                color: ThemeManager.textColor; font.pixelSize: 12; font.family: "Consolas"
                                selectByMouse: true
                                onEditingFinished: behaviourObject.updateEventField(root.selectedEventId, "cronExpression", text)
                            }
                        }
                        // Preset chips
                        Flow {
                            Layout.fillWidth: true; spacing: 4
                            Repeater {
                                model: ["@hourly","@daily","@weekly","0 9 * * 1-5","*/30 * * * *"]
                                Rectangle {
                                    height: 20; width: chipT.implicitWidth + 14; radius: 10
                                    color: chipCA.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                    border.width: 1; border.color: Qt.rgba(1,1,1,0.12)
                                    Text { id: chipT; anchors.centerIn: parent; text: modelData; color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.family: "Consolas" }
                                    MouseArea {
                                        id: chipCA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            cronInput.text = modelData
                                            behaviourObject.updateEventField(root.selectedEventId, "cronExpression", modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Multi-Date calendar ───────────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        visible: root.selectedEvent && root.selectedEvent.triggerType === 3

                        CalendarView {
                            id: schedCal
                            Layout.fillWidth: true
                            height: 290
                            multiSelect: true
                            compact: false
                            selectedDates: {
                                if (!root.selectedEvent) return []
                                return root.selectedEvent.dateTimes.map(function(dt) {
                                    return dt.substring(0, 10)
                                })
                            }
                            markedDates: selectedDates
                            onSelectionChanged: function(dates) {
                                var isoList = dates.map(function(d) {
                                    return d + "T00:00:00"
                                })
                                behaviourObject.setEventDates(root.selectedEventId, isoList)
                            }
                        }

                        // Time of day for multi-date
                        RowLayout {
                            Layout.fillWidth: true; spacing: 6
                            Text { text: "Hora:"; color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                            TimePicker {
                                hours:   root.selectedEvent ? root.selectedEvent.multiTimeHour   : 9
                                minutes: root.selectedEvent ? root.selectedEvent.multiTimeMinute : 0
                                seconds: root.selectedEvent ? root.selectedEvent.multiTimeSecond : 0
                                showSeconds: false
                                implicitWidth: 130; implicitHeight: 70
                                onTimeChanged: function(h, m, s) {
                                    if (!root.selectedEventId) return
                                    behaviourObject.updateEventField(root.selectedEventId, "multiTimeHour",   h)
                                    behaviourObject.updateEventField(root.selectedEventId, "multiTimeMinute", m)
                                    behaviourObject.updateEventField(root.selectedEventId, "multiTimeSecond", s)
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

                    // ── Script ────────────────────────────────────────────────
                    Text { text: "SCRIPT"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1 }

                    // Inline / File toggle
                    RowLayout {
                        Layout.fillWidth: true; spacing: 0
                        Repeater {
                            model: ["Inline","Arquivo"]
                            Rectangle {
                                Layout.fillWidth: true; height: 28
                                radius: index === 0 ? 5 : 0
                                color: {
                                    var mode = root.selectedEvent ? root.selectedEvent.scriptMode : 0
                                    return mode === index ? ThemeManager.primaryColor : Qt.rgba(1,1,1,0.05)
                                }
                                border.width: 1; border.color: Qt.rgba(1,1,1,0.12)
                                Text { anchors.centerIn: parent; text: modelData; color: "#fff"; font.pixelSize: 11 }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: behaviourObject.updateEventField(root.selectedEventId, "scriptMode", index)
                                }
                            }
                        }
                    }

                    // Inline code editor
                    Rectangle {
                        Layout.fillWidth: true; height: 120; radius: 6
                        color: Qt.rgba(0,0,0,0.3)
                        border.width: 1; border.color: Qt.rgba(1,1,1,0.1)
                        visible: !root.selectedEvent || root.selectedEvent.scriptMode === 0
                        clip: true

                        ScrollView {
                            anchors.fill: parent; clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            TextArea {
                                id: scriptEditor
                                text: root.selectedEvent ? root.selectedEvent.scriptCode : ""
                                color: ThemeManager.textColor
                                font.pixelSize: 11; font.family: "Consolas"
                                background: null
                                leftPadding: 8; topPadding: 6
                                wrapMode: TextArea.NoWrap
                                onEditingFinished: behaviourObject.updateEventField(root.selectedEventId, "scriptCode", text)
                                // sync when event changes
                                Connections {
                                    target: root
                                    function onSelectedEventChanged() {
                                        if (root.selectedEvent)
                                            scriptEditor.text = root.selectedEvent.scriptCode
                                    }
                                }
                            }
                        }
                    }

                    // File path
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.selectedEvent && root.selectedEvent.scriptMode === 1
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true; height: 34; radius: 6
                            color: Qt.rgba(1,1,1,0.05)
                            border.width: 1; border.color: Qt.rgba(1,1,1,0.12)
                            TextField {
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.selectedEvent ? root.selectedEvent.scriptFile : ""
                                color: ThemeManager.textColor; font.pixelSize: 11; font.family: "Consolas"
                                selectByMouse: true
                                placeholderText: "Caminho do arquivo .py"
                                placeholderTextColor: Qt.rgba(1,1,1,0.3)
                                background: null
                                onEditingFinished: behaviourObject.updateEventField(root.selectedEventId, "scriptFile", text)
                            }
                        }

                        Rectangle {
                            width: 34; height: 34; radius: 6
                            color: browseBtnA.containsMouse ? Qt.lighter(ThemeManager.primaryColor,1.2) : ThemeManager.primaryColor
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { anchors.centerIn: parent; text: "📁"; color: "#fff"; font.pixelSize: 14 }
                            MouseArea {
                                id: browseBtnA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: fileDialog.open()
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

                    // ── Params ────────────────────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "PARÂMETROS"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1; Layout.fillWidth: true }
                        Rectangle {
                            width: 22; height: 22; radius: 4
                            color: addParamA.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text { anchors.centerIn: parent; text: "+"; color: ThemeManager.primaryColor; font.pixelSize: 14; font.bold: true }
                            MouseArea { id: addParamA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: behaviourObject.addEventParam(root.selectedEventId, "param" + Date.now(), "value")
                            }
                        }
                    }

                    Column {
                        Layout.fillWidth: true; spacing: 4
                        Repeater {
                            model: root.selectedEvent && root.selectedEvent.params
                                ? Object.keys(root.selectedEvent.params) : []
                            RowLayout {
                                width: parent.width; spacing: 4
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; radius: 5
                                    color: Qt.rgba(1,1,1,0.04); border.width:1; border.color: Qt.rgba(1,1,1,0.1)
                                    TextInput {
                                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: modelData; color: ThemeManager.textSecondaryColor; font.pixelSize: 11; font.family: "Consolas"
                                        readOnly: true
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true; height: 28; radius: 5
                                    color: Qt.rgba(1,1,1,0.04); border.width:1; border.color: Qt.rgba(1,1,1,0.1)
                                    TextInput {
                                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: root.selectedEvent.params[modelData] || ""
                                        color: ThemeManager.textColor; font.pixelSize: 11
                                        selectByMouse: true
                                        onEditingFinished: behaviourObject.addEventParam(root.selectedEventId, modelData, text)
                                    }
                                }
                                Rectangle {
                                    width: 22; height: 22; radius: 4
                                    color: rmPA.containsMouse ? Qt.rgba(239,68,68,0.2) : "transparent"
                                    Text { anchors.centerIn: parent; text: "✕"; color: "#EF4444"; font.pixelSize: 10 }
                                    MouseArea { id: rmPA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: behaviourObject.removeEventParam(root.selectedEventId, modelData)
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

                    // ── Last run / Fire now ───────────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        ColumnLayout {
                            spacing: 2
                            Text { text: "Último disparo"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                            Text {
                                text: root.selectedEvent && root.selectedEvent.lastRun.length > 0
                                    ? root.selectedEvent.lastRun : "—"
                                color: ThemeManager.textColor; font.pixelSize: 10
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 80; height: 28; radius: 6
                            color: fireNowA.containsMouse ? Qt.lighter(ThemeManager.primaryColor,1.2) : ThemeManager.primaryColor
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { anchors.centerIn: parent; text: "⚡ Disparar"; color: "#fff"; font.pixelSize: 11; font.bold: true }
                            MouseArea {
                                id: fireNowA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: behaviourObject.triggerEvent(root.selectedEventId)
                            }
                        }
                    }

                    Item { height: 10 }
                }
            }
        }
    }

    Platform.FileDialog {
        id: fileDialog
        title: "Selecione o Script Python"
        nameFilters: ["Python Scripts (*.py)", "All Files (*)"]
        onAccepted: {
            if (root.selectedEventId !== "") {
                var p = fileDialog.file.toString().replace("file:///", "")
                behaviourObject.updateEventField(root.selectedEventId, "scriptFile", p)
            }
        }
    }
}
