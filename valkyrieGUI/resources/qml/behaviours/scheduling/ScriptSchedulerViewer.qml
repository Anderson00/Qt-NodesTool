import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qt.labs.platform 1.1 as Platform
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property string selectedEventId: ""
    property var    selectedEvent:   null

    readonly property var triggerTypes: ["Intervalo","Data/Hora","Cron","Multi-Data"]
    readonly property var triggerIcons: [Icons.timerOutline, Icons.calendarOutline, Icons.refresh, Icons.calendarOutline]

    // Clock tick used by delegates to recompute countdowns without model refresh
    property int _clockTick: 0
    Timer {
        interval: 1000
        running: behaviourObject && behaviourObject.active
        repeat: true
        onTriggered: root._clockTick++
    }

    // ── Console ────────────────────────────────────────────────────────────────
    property bool _consoleOpen: true
    property var  _consoleLogs: []

    function _addLog(type, eventId, text) {
        var evName = eventId
        if (behaviourObject) {
            var ev = behaviourObject.getEvent(eventId)
            if (ev && ev.name) evName = ev.name
        }
        var logs = _consoleLogs.slice()
        logs.unshift({
            type: type,
            time: Qt.formatDateTime(new Date(), "HH:mm:ss"),
            event: evName,
            text: (text && text.length > 0) ? text : "(sem saída)"
        })
        if (logs.length > 300) logs.length = 300
        _consoleLogs = logs
    }

    function formatCountdown(nextFireMs) {
        if (!nextFireMs || nextFireMs <= 0) return ""
        var left = Math.max(0, nextFireMs - Date.now())
        if (left === 0) return "agora"
        var s = Math.ceil(left / 1000)
        var h = Math.floor(s / 3600); s = s % 3600
        var m = Math.floor(s / 60);   s = s % 60
        if (h > 0) return h + "h " + m + "m " + s + "s"
        if (m > 0) return m + "m " + s + "s"
        return s + "s"
    }

    function refreshSelected() {
        if (!behaviourObject || selectedEventId === "") { selectedEvent = null; return }
        selectedEvent = behaviourObject.getEvent(selectedEventId)
    }

    // Re-populate text fields when the selected event changes.
    // QML TextInput breaks its declarative binding on first user edit, so switching
    // events would leave stale text without this explicit reset.
    onSelectedEventIdChanged: {
        if (!behaviourObject || selectedEventId === "") return
        var ev = behaviourObject.getEvent(selectedEventId)
        if (!ev) return
        // Restore all fields whose QML bindings are broken by user interaction
        nameField.text     = ev.name           || ""
        cronInput.text     = ev.cronExpression || "0 * * * *"
        filePathField.text = ev.scriptFile     || ""
        inlineEditor.code  = ev.scriptCode     || ""
        daysSpinBox.value  = ev.days  !== undefined ? ev.days    : 0
        hoursSpinBox.value = ev.hours !== undefined ? ev.hours   : 1
        minsSpinBox.value  = ev.minutes !== undefined ? ev.minutes : 0
        secsSpinBox.value  = ev.seconds !== undefined ? ev.seconds : 0
    }

    Connections {
        target: behaviourObject
        function onEventsChanged() { root.refreshSelected() }

        function onEventScriptFinished(eventId, outputs) {
            var text = outputs["stdout"] || outputs["output"] || outputs["_out"] || ""
            if (!text) {
                var lines = []
                var skip = ["event_id","event_name","run_count","timestamp"]
                for (var k in outputs) {
                    if (skip.indexOf(k) < 0) lines.push(k + " = " + outputs[k])
                }
                text = lines.join("\n")
            }
            root._addLog("ok", eventId, text)
        }

        function onEventScriptError(eventId, error) {
            root._addLog("err", eventId, error)
        }
    }

    // ── Root layout ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ══════════════ TOP — Scheduler control bar ════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: Qt.rgba(0,0,0,0.3)

            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 10 }
                spacing: 8

                // Status dot
                Rectangle {
                    width: 7; height: 7; radius: 3.5
                    color: behaviourObject && behaviourObject.active
                        ? "#22C55E" : Qt.rgba(1,1,1,0.2)
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Text {
                    text: behaviourObject && behaviourObject.active
                        ? "Agendador ativo" : "Agendador parado"
                    color: behaviourObject && behaviourObject.active
                        ? ThemeManager.textColor : ThemeManager.textSecondaryColor
                    font.pixelSize: 11
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                // Countdown to next event — defensive: nextEventIn may not exist in C++
                Rectangle {
                    id: countdownPill

                    // Safely read nextEventIn: undefined or "undefined" → ""
                    property string _ni: {
                        if (!behaviourObject) return ""
                        var v = behaviourObject.nextEventIn
                        if (v === undefined || v === null) return ""
                        var s = String(v)
                        return (s === "undefined" || s.length === 0) ? "" : s
                    }

                    visible: !!(behaviourObject && behaviourObject.active) && _ni.length > 0
                    height: 20; width: nextLabel.implicitWidth + 14; radius: 10
                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                   ThemeManager.primaryColor.g,
                                   ThemeManager.primaryColor.b, 0.15)
                    border.width: 1
                    border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                          ThemeManager.primaryColor.g,
                                          ThemeManager.primaryColor.b, 0.3)
                    RowLayout {
                        id: nextLabel
                        anchors.centerIn: parent; spacing: 4
                        SvgIcon { width: 11; height: 11; source: Icons.timerSand; color: ThemeManager.primaryColor }
                        Text {
                            text: countdownPill._ni
                            color: ThemeManager.primaryColor
                            font.pixelSize: 10; font.bold: true; font.family: "Consolas"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Start / Stop button
                Rectangle {
                    id: startStopRect
                    height: 26
                    width: startStopLabel.implicitWidth + 18; radius: 6

                    property bool _isActive: !!(behaviourObject && behaviourObject.active)

                    // Hover uses Qt.darker (not lighter) to keep contrast for white text
                    color: startStopA.containsMouse
                        ? (_isActive ? "#991B1B" : Qt.darker(ThemeManager.primaryColor, 1.2))
                        : (_isActive ? "#DC2626" : ThemeManager.primaryColor)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        id: startStopLabel
                        anchors.centerIn: parent; spacing: 5
                        SvgIcon {
                            Layout.preferredWidth: 12; Layout.preferredHeight: 12
                            source: startStopRect._isActive ? Icons.stop : Icons.play
                            color: "#ffffff"
                        }
                        Text {
                            text: startStopRect._isActive ? "Parar" : "Iniciar"
                            color: "#ffffff"
                            font.pixelSize: 11; font.bold: true
                            style: Text.Outline
                            styleColor: Qt.rgba(0, 0, 0, 0.25)
                        }
                    }
                    MouseArea {
                        id: startStopA; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!behaviourObject) {
                                console.warn("[ScriptScheduler] behaviourObject is null — cannot toggle")
                                return
                            }
                            var wasActive = behaviourObject.active
                            console.log("[ScriptScheduler] toggle click — active=" + wasActive)
                            if (wasActive) {
                                behaviourObject.stopScheduler()
                                console.log("[ScriptScheduler] stopScheduler() called")
                            } else {
                                behaviourObject.startScheduler()
                                console.log("[ScriptScheduler] startScheduler() called")
                            }
                            console.log("[ScriptScheduler] new active=" + behaviourObject.active)
                        }
                    }
                }
            }
        }

        // Separator
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.07) }

        // ══════════════ MAIN — List + Editor ══════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ══════════════ LEFT — Event List ═════════════════════════════════
            Rectangle {
                Layout.preferredWidth: 152
                Layout.fillHeight: true
                color: Qt.rgba(0,0,0,0.2)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    // Header
                    RowLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text {
                            text: "EVENTOS"
                            color: ThemeManager.textSecondaryColor
                            font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: Qt.rgba(1,1,1,0.08)
                            Text {
                                anchors.centerIn: parent
                                text: behaviourObject ? behaviourObject.eventCount + "" : "0"
                                color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.bold: true
                            }
                        }
                    }

                    // List
                    ListView {
                        id: eventList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true; spacing: 2
                        model: behaviourObject ? behaviourObject.events : []

                        delegate: Rectangle {
                            width: eventList.width; height: nextInVisible ? 58 : 48
                            radius: 6
                            property bool isSelected: modelData.id === root.selectedEventId
                            property string _countdown: {
                                root._clockTick  // reactive tick dependency
                                return root.formatCountdown(modelData.nextFireMs || 0)
                            }
                            property bool nextInVisible: _countdown.length > 0

                            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                            color: isSelected
                                ? Qt.rgba(ThemeManager.primaryColor.r,
                                          ThemeManager.primaryColor.g,
                                          ThemeManager.primaryColor.b, 0.18)
                                : (itemArea.containsMouse ? Qt.rgba(1,1,1,0.07) : "transparent")
                            border.width: isSelected ? 1 : 0
                            border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                                  ThemeManager.primaryColor.g,
                                                  ThemeManager.primaryColor.b, 0.4)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            ColumnLayout {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 6; topMargin: 4; bottomMargin: 4 }
                                spacing: 1

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 6

                                    // Status dot
                                    Rectangle {
                                        width: 6; height: 6; radius: 3
                                        Layout.alignment: Qt.AlignVCenter
                                        color: modelData.enabled ? "#22C55E" : Qt.rgba(1,1,1,0.2)
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name; elide: Text.ElideRight
                                            color: ThemeManager.textColor
                                            font.pixelSize: 11
                                            font.bold: isSelected
                                        }
                                        RowLayout {
                                            spacing: 3
                                            SvgIcon {
                                                width: 9; height: 9
                                                source: root.triggerIcons[modelData.triggerType] || ""
                                                color: ThemeManager.textSecondaryColor
                                            }
                                            Text {
                                                text: root.triggerTypes[modelData.triggerType] || "?"
                                                color: ThemeManager.textSecondaryColor; font.pixelSize: 9
                                            }
                                        }
                                    }

                                    // Delete
                                    Rectangle {
                                        width: 20; height: 20; radius: 4
                                        color: delA.containsMouse ? Qt.rgba(239,68,68,0.25) : "transparent"
                                        visible: itemArea.containsMouse || delA.containsMouse
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        SvgIcon { anchors.centerIn: parent; width: 10; height: 10; source: Icons.close; color: "#EF4444" }
                                        MouseArea {
                                            id: delA; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.id === root.selectedEventId) {
                                                    root.selectedEventId = ""; root.selectedEvent = null
                                                }
                                                behaviourObject.removeEvent(modelData.id)
                                            }
                                        }
                                    }
                                }

                                // Per-event countdown
                                Rectangle {
                                    Layout.fillWidth: true; height: 16; radius: 4
                                    visible: nextInVisible
                                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                                   ThemeManager.primaryColor.g,
                                                   ThemeManager.primaryColor.b, 0.12)
                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 5; rightMargin: 5 }
                                        spacing: 3
                                        SvgIcon { width: 10; height: 10; source: Icons.timerSand; color: ThemeManager.primaryColor }
                                        Text {
                                            Layout.fillWidth: true
                                            text: _countdown
                                            color: ThemeManager.primaryColor
                                            font.pixelSize: 9; font.family: "Consolas"; font.bold: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemArea; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { root.selectedEventId = modelData.id; root.refreshSelected() }
                            }
                        }
                    }

                    // Add button
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 7
                        color: addA.containsMouse
                            ? Qt.lighter(ThemeManager.primaryColor, 1.15)
                            : ThemeManager.primaryColor
                        Behavior on color { ColorAnimation { duration: 150 } }
                        RowLayout {
                            anchors.centerIn: parent; spacing: 5
                            SvgIcon { width: 16; height: 16; source: Icons.plus; color: "#fff" }
                            Text { text: "Evento"; color: "#fff"; font.pixelSize: 11; font.bold: true }
                        }
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
            Rectangle { width: 1; Layout.fillHeight: true; color: Qt.rgba(1,1,1,0.07) }

            // ══════════════ RIGHT — Event Editor ══════════════════════════════
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent; spacing: 10
                    visible: root.selectedEvent === null
                    SvgIcon { Layout.alignment: Qt.AlignHCenter; width: 36; height: 36; source: Icons.clipboardTextOutline; color: ThemeManager.textColor; opacity: 0.2 }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Selecione ou crie\num evento"
                        color: Qt.rgba(1,1,1,0.22); font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Editor
                ScrollView {
                    id: editorScroll
                    anchors.fill: parent
                    visible: root.selectedEvent !== null
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: editorScroll.availableWidth
                        spacing: 0

                        // ── Name + Enabled ─────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            height: headerCol.implicitHeight + 24
                            color: Qt.rgba(0,0,0,0.15)

                            ColumnLayout {
                                id: headerCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 10

                                Rectangle {
                                    Layout.fillWidth: true; height: 36; radius: 7
                                    color: Qt.rgba(1,1,1,0.06)
                                    border.width: 1
                                    border.color: nameField.activeFocus
                                        ? ThemeManager.primaryColor : Qt.rgba(1,1,1,0.14)
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 6
                                        SvgIcon { width: 14; height: 14; source: Icons.pencilOutline; color: ThemeManager.textSecondaryColor; opacity: 0.5 }
                                        TextInput {
                                            id: nameField
                                            Layout.fillWidth: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: root.selectedEvent ? root.selectedEvent.name : ""
                                            color: ThemeManager.textColor; font.pixelSize: 13; font.bold: true
                                            selectByMouse: true
                                            onEditingFinished: {
                                                if (root.selectedEventId !== "")
                                                    behaviourObject.updateEventField(root.selectedEventId, "name", text)
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8
                                    CustomSwitch {
                                        text: "Evento ativo"
                                        checked: root.selectedEvent ? root.selectedEvent.enabled : false
                                        onCheckedChanged: {
                                            if (root.selectedEventId !== "")
                                                behaviourObject.updateEventField(root.selectedEventId, "enabled", checked)
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        height: 22; width: runBadge.implicitWidth + 16; radius: 11
                                        color: Qt.rgba(1,1,1,0.07)
                                        RowLayout {
                                            id: runBadge; anchors.centerIn: parent; spacing: 3
                                            SvgIcon { width: 10; height: 10; source: Icons.restore; color: ThemeManager.textSecondaryColor }
                                            Text {
                                                text: root.selectedEvent ? root.selectedEvent.runCount : "0"
                                                color: ThemeManager.textColor; font.pixelSize: 10; font.bold: true
                                            }
                                            Text { text: "execuções"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Trigger Type ───────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.topMargin: 14
                            spacing: 8

                            Text {
                                text: "TIPO DE TRIGGER"
                                color: ThemeManager.textSecondaryColor
                                font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2
                            }

                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 6; rowSpacing: 6
                                Repeater {
                                    model: root.triggerTypes
                                    Rectangle {
                                        Layout.fillWidth: true; height: 38; radius: 7
                                        property bool isActive: root.selectedEvent &&
                                                                root.selectedEvent.triggerType === index
                                        color: isActive
                                            ? Qt.rgba(ThemeManager.primaryColor.r,
                                                      ThemeManager.primaryColor.g,
                                                      ThemeManager.primaryColor.b, 0.2)
                                            : (trigBtn.containsMouse ? Qt.rgba(1,1,1,0.07) : Qt.rgba(1,1,1,0.04))
                                        border.width: 1
                                        border.color: isActive
                                            ? Qt.rgba(ThemeManager.primaryColor.r,
                                                      ThemeManager.primaryColor.g,
                                                      ThemeManager.primaryColor.b, 0.55)
                                            : Qt.rgba(1,1,1,0.1)
                                        Behavior on color      { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }
                                        RowLayout {
                                            anchors.centerIn: parent; spacing: 6
                                            SvgIcon { width: 14; height: 14; source: root.triggerIcons[index]; color: isActive ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor }
                                            Text {
                                                text: modelData; font.pixelSize: 11; font.bold: isActive
                                                color: isActive ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                                                Behavior on color { ColorAnimation { duration: 120 } }
                                            }
                                        }
                                        MouseArea {
                                            id: trigBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.selectedEventId !== "")
                                                    behaviourObject.updateEventField(root.selectedEventId, "triggerType", index)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Interval fields (type 0) ───────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.topMargin: 10
                            visible: root.selectedEvent && root.selectedEvent.triggerType === 0

                            Rectangle {
                                Layout.fillWidth: true
                                height: intervalRow.implicitHeight + 16
                                radius: 8; color: Qt.rgba(0,0,0,0.18)
                                border.width: 1; border.color: Qt.rgba(1,1,1,0.07)

                                RowLayout {
                                    id: intervalRow
                                    anchors { fill: parent; margins: 10 } spacing: 8

                                    // Explicit items (not Repeater) so each SpinBox has an id
                                    // and can be reset in onSelectedEventIdChanged when switching events.
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { Layout.alignment: Qt.AlignHCenter; text: "Dias"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                                        VerticalSpinBox {
                                            id: daysSpinBox; Layout.alignment: Qt.AlignHCenter
                                            from: 0; to: 999
                                            value: root.selectedEvent ? root.selectedEvent.days : 0
                                            onValueModified: function(v) {
                                                if (root.selectedEventId !== "")
                                                    behaviourObject.updateEventField(root.selectedEventId, "days", v)
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { Layout.alignment: Qt.AlignHCenter; text: "Horas"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                                        VerticalSpinBox {
                                            id: hoursSpinBox; Layout.alignment: Qt.AlignHCenter
                                            from: 0; to: 999
                                            value: root.selectedEvent ? root.selectedEvent.hours : 1
                                            onValueModified: function(v) {
                                                if (root.selectedEventId !== "")
                                                    behaviourObject.updateEventField(root.selectedEventId, "hours", v)
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { Layout.alignment: Qt.AlignHCenter; text: "Min"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                                        VerticalSpinBox {
                                            id: minsSpinBox; Layout.alignment: Qt.AlignHCenter
                                            from: 0; to: 999
                                            value: root.selectedEvent ? root.selectedEvent.minutes : 0
                                            onValueModified: function(v) {
                                                if (root.selectedEventId !== "")
                                                    behaviourObject.updateEventField(root.selectedEventId, "minutes", v)
                                            }
                                        }
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true; spacing: 4
                                        Text { Layout.alignment: Qt.AlignHCenter; text: "Seg"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                                        VerticalSpinBox {
                                            id: secsSpinBox; Layout.alignment: Qt.AlignHCenter
                                            from: 0; to: 999
                                            value: root.selectedEvent ? root.selectedEvent.seconds : 0
                                            onValueModified: function(v) {
                                                if (root.selectedEventId !== "")
                                                    behaviourObject.updateEventField(root.selectedEventId, "seconds", v)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── Single DateTime (type 1) ───────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.topMargin: 10
                            visible: root.selectedEvent && root.selectedEvent.triggerType === 1

                            Rectangle {
                                Layout.fillWidth: true; height: 72; radius: 8
                                color: Qt.rgba(0,0,0,0.18); border.width: 1; border.color: Qt.rgba(1,1,1,0.07)
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 4
                                    SvgIcon { Layout.alignment: Qt.AlignHCenter; width: 28; height: 28; source: Icons.calendarOutline; color: ThemeManager.textSecondaryColor; opacity: 0.5 }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: root.selectedEvent && root.selectedEvent.dateTimes &&
                                              root.selectedEvent.dateTimes.length > 0
                                            ? root.selectedEvent.dateTimes[0] : "Nenhuma data definida"
                                        color: ThemeManager.textSecondaryColor; font.pixelSize: 11
                                    }
                                }
                            }
                        }

                        // ── Cron (type 2) ──────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.topMargin: 10
                            spacing: 8
                            visible: root.selectedEvent && root.selectedEvent.triggerType === 2

                            Rectangle {
                                Layout.fillWidth: true; height: 38; radius: 7
                                color: Qt.rgba(1,1,1,0.05)
                                border.width: 1
                                border.color: cronInput.activeFocus ? ThemeManager.primaryColor : Qt.rgba(1,1,1,0.12)
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                RowLayout {
                                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 6
                                    SvgIcon { width: 14; height: 14; source: Icons.codeBraces; color: ThemeManager.primaryColor; opacity: 0.7 }
                                    TextInput {
                                        id: cronInput
                                        Layout.fillWidth: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: root.selectedEvent ? root.selectedEvent.cronExpression : "0 * * * *"
                                        color: ThemeManager.textColor; font.pixelSize: 13; font.family: "Consolas"
                                        selectByMouse: true
                                        onEditingFinished: behaviourObject.updateEventField(root.selectedEventId, "cronExpression", text)
                                    }
                                }
                            }

                            Flow {
                                Layout.fillWidth: true; spacing: 4
                                Repeater {
                                    model: ["@hourly","@daily","@weekly","@monthly","0 9 * * 1-5","*/30 * * * *","*/5 * * * *"]
                                    Rectangle {
                                        height: 22; width: chipCT.implicitWidth + 14; radius: 11
                                        color: chipCA.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                                        border.width: 1; border.color: Qt.rgba(1,1,1,0.12)
                                        Text { id: chipCT; anchors.centerIn: parent; text: modelData; color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.family: "Consolas" }
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

                        // ── Multi-Date with range (type 3) ─────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.topMargin: 10
                            spacing: 8
                            visible: root.selectedEvent && root.selectedEvent.triggerType === 3

                            CalendarView {
                                id: schedCal
                                Layout.fillWidth: true
                                height: 300
                                rangeSelect: true
                                compact: true
                                selectedDates: {
                                    if (!root.selectedEvent) return []
                                    return root.selectedEvent.dateTimes.map(function(dt) { return dt.substring(0, 10) })
                                }
                                markedDates: selectedDates
                                onSelectionChanged: function(dates) {
                                    var isoList = dates.map(function(d) { return d + "T00:00:00" })
                                    behaviourObject.setEventDates(root.selectedEventId, isoList)
                                }
                                onRangeChanged: function(s, e) {
                                    // rangeChanged fires after selectionChanged, no extra action needed
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
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

                        // Divider
                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.07); Layout.topMargin: 14 }

                        // ── Script Section ─────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.topMargin: 14
                            spacing: 10

                            Text {
                                text: "SCRIPT"
                                color: ThemeManager.textSecondaryColor
                                font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2
                            }

                            // Mode toggle
                            Rectangle {
                                Layout.fillWidth: true; height: 30; radius: 7
                                color: Qt.rgba(0,0,0,0.25); border.width: 1; border.color: Qt.rgba(1,1,1,0.08)
                                RowLayout {
                                    anchors { fill: parent; margins: 3 } spacing: 3
                                    Repeater {
                                        model: ["Inline", "Arquivo"]
                                        Rectangle {
                                            Layout.fillWidth: true; height: parent.height; radius: 5
                                            property bool isCurrent: {
                                                var m = root.selectedEvent ? root.selectedEvent.scriptMode : 0
                                                return m === index
                                            }
                                            color: isCurrent ? Qt.rgba(1,1,1,0.12) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            RowLayout {
                                                anchors.centerIn: parent; spacing: 5
                                                SvgIcon {
                                                    width: 12; height: 12
                                                    source: index === 0 ? Icons.codeBraces : Icons.fileDocumentOutline
                                                    color: isCurrent ? ThemeManager.textColor : ThemeManager.textSecondaryColor
                                                }
                                                Text {
                                                    text: modelData
                                                    color: isCurrent ? ThemeManager.textColor : ThemeManager.textSecondaryColor
                                                    font.pixelSize: 11; font.bold: isCurrent
                                                }
                                            }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: behaviourObject.updateEventField(root.selectedEventId, "scriptMode", index)
                                            }
                                        }
                                    }
                                }
                            }

                            // Inline: CodeEditor
                            CodeEditor {
                                id: inlineEditor
                                Layout.fillWidth: true; height: 200
                                visible: !root.selectedEvent || root.selectedEvent.scriptMode === 0
                                code: root.selectedEvent ? root.selectedEvent.scriptCode : ""
                                fontSize: 12
                                onCodeModified: function(newCode) {
                                    if (root.selectedEventId !== "")
                                        behaviourObject.updateEventField(root.selectedEventId, "scriptCode", newCode)
                                }
                            }

                            // File mode
                            RowLayout {
                                Layout.fillWidth: true; spacing: 8
                                visible: root.selectedEvent && root.selectedEvent.scriptMode === 1
                                Rectangle {
                                    Layout.fillWidth: true; height: 36; radius: 7
                                    color: Qt.rgba(1,1,1,0.05); border.width: 1; border.color: Qt.rgba(1,1,1,0.12)
                                    RowLayout {
                                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 6
                                        SvgIcon { width: 14; height: 14; source: Icons.fileDocumentOutline; color: ThemeManager.textSecondaryColor; opacity: 0.6 }
                                        TextField {
                                            id: filePathField
                                            Layout.fillWidth: true
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: root.selectedEvent ? root.selectedEvent.scriptFile : ""
                                            color: ThemeManager.textColor; font.pixelSize: 11; font.family: "Consolas"
                                            selectByMouse: true; placeholderText: "Caminho do arquivo .py"
                                            placeholderTextColor: Qt.rgba(1,1,1,0.3); background: null
                                            onEditingFinished: behaviourObject.updateEventField(root.selectedEventId, "scriptFile", text)
                                        }
                                    }
                                }
                                Rectangle {
                                    width: 36; height: 36; radius: 7
                                    color: browseBtnA.containsMouse
                                        ? Qt.lighter(ThemeManager.primaryColor, 1.2) : ThemeManager.primaryColor
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    SvgIcon { anchors.centerIn: parent; width: 16; height: 16; source: Icons.folderOutline; color: "#fff" }
                                    MouseArea { id: browseBtnA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: fileDialog.open() }
                                }
                            }
                        }

                        // Divider
                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.07); Layout.topMargin: 14 }

                        // ── Params Section ─────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12; Layout.rightMargin: 12; Layout.topMargin: 14
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "PARÂMETROS"
                                    color: ThemeManager.textSecondaryColor
                                    font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2
                                    Layout.fillWidth: true
                                }
                                Rectangle {
                                    width: 24; height: 24; radius: 6
                                    color: addParamA.containsMouse
                                        ? Qt.rgba(ThemeManager.primaryColor.r,
                                                  ThemeManager.primaryColor.g,
                                                  ThemeManager.primaryColor.b, 0.2)
                                        : Qt.rgba(1,1,1,0.06)
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    SvgIcon { anchors.centerIn: parent; width: 14; height: 14; source: Icons.plus; color: ThemeManager.primaryColor }
                                    MouseArea {
                                        id: addParamA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var count = root.selectedEvent && root.selectedEvent.params
                                                ? Object.keys(root.selectedEvent.params).length + 1 : 1
                                            behaviourObject.addEventParam(root.selectedEventId, "param" + count, "")
                                        }
                                    }
                                }
                            }

                            // Param rows
                            Column {
                                Layout.fillWidth: true; spacing: 4
                                Repeater {
                                    model: root.selectedEvent && root.selectedEvent.params
                                        ? Object.keys(root.selectedEvent.params) : []

                                    // Param delegate — key is editable, value is editable
                                    Rectangle {
                                        id: paramRow
                                        width: parent.width; height: 32; radius: 6
                                        color: Qt.rgba(1,1,1,0.04)
                                        border.width: 1; border.color: Qt.rgba(1,1,1,0.09)

                                        property string _currentKey: modelData
                                        property string _currentVal: root.selectedEvent
                                            ? (root.selectedEvent.params[modelData] || "") : ""

                                        RowLayout {
                                            anchors { fill: parent; leftMargin: 8; rightMargin: 6 }
                                            spacing: 0

                                            // Key (editable — supports rename)
                                            TextInput {
                                                id: keyInput
                                                Layout.preferredWidth: 70
                                                verticalAlignment: TextInput.AlignVCenter
                                                height: parent.height
                                                text: paramRow._currentKey
                                                color: ThemeManager.primaryColor; opacity: 0.75
                                                font.pixelSize: 11; font.family: "Consolas"
                                                selectByMouse: true
                                                onEditingFinished: {
                                                    var newKey = text.trim()
                                                    if (newKey.length === 0 || newKey === paramRow._currentKey) return
                                                    var val = paramRow._currentVal
                                                    behaviourObject.removeEventParam(root.selectedEventId, paramRow._currentKey)
                                                    behaviourObject.addEventParam(root.selectedEventId, newKey, val)
                                                    paramRow._currentKey = newKey
                                                }
                                            }

                                            // Separator
                                            Text { text: " : "; color: Qt.rgba(1,1,1,0.25); font.pixelSize: 12 }

                                            // Value (editable)
                                            TextInput {
                                                id: valInput
                                                Layout.fillWidth: true
                                                verticalAlignment: TextInput.AlignVCenter
                                                height: parent.height
                                                text: paramRow._currentVal
                                                color: ThemeManager.textColor; font.pixelSize: 11
                                                selectByMouse: true
                                                onEditingFinished: {
                                                    paramRow._currentVal = text
                                                    behaviourObject.addEventParam(root.selectedEventId, paramRow._currentKey, text)
                                                }
                                            }

                                            // Delete
                                            Rectangle {
                                                width: 20; height: 20; radius: 4
                                                color: rmPA.containsMouse ? Qt.rgba(239,68,68,0.2) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 100 } }
                                                SvgIcon { anchors.centerIn: parent; width: 10; height: 10; source: Icons.close; color: "#EF4444" }
                                                MouseArea {
                                                    id: rmPA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: behaviourObject.removeEventParam(root.selectedEventId, paramRow._currentKey)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Divider
                        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.07); Layout.topMargin: 14 }

                        // ── Footer: last run + fire ────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 12; Layout.rightMargin: 12
                            Layout.topMargin: 10; Layout.bottomMargin: 16
                            spacing: 8

                            ColumnLayout {
                                spacing: 2
                                Text { text: "Último disparo"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                                Text {
                                    text: root.selectedEvent && root.selectedEvent.lastRun &&
                                          root.selectedEvent.lastRun.length > 0
                                        ? root.selectedEvent.lastRun : "—"
                                    color: ThemeManager.textColor; font.pixelSize: 10
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                height: 32; width: fireLabel.implicitWidth + 24; radius: 7
                                color: fireNowA.containsMouse
                                    ? Qt.lighter(ThemeManager.primaryColor, 1.15)
                                    : ThemeManager.primaryColor
                                Behavior on color { ColorAnimation { duration: 150 } }
                                RowLayout { id: fireLabel; anchors.centerIn: parent; spacing: 5
                                    SvgIcon { width: 12; height: 12; source: Icons.flash; color: "#fff" }
                                    Text { text: "Disparar agora"; color: "#fff"; font.pixelSize: 11; font.bold: true }
                                }
                                MouseArea {
                                    id: fireNowA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: behaviourObject.triggerEvent(root.selectedEventId)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ══════════════ CONSOLE ═══════════════════════════════════════════════
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.07) }

        Rectangle {
            Layout.fillWidth: true
            height: root._consoleOpen ? 150 : 28
            color: Qt.rgba(0,0,0,0.25)
            clip: true
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Rectangle {
                    Layout.fillWidth: true; height: 28
                    color: Qt.rgba(0,0,0,0.18)

                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                        spacing: 6

                        SvgIcon { width: 11; height: 11; source: Icons.codeBraces; color: ThemeManager.textSecondaryColor; opacity: 0.7 }
                        Text {
                            text: "SAÍDA"
                            color: ThemeManager.textSecondaryColor
                            font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.2
                        }

                        // Total entries badge
                        Rectangle {
                            height: 14; width: logCountTxt.implicitWidth + 10; radius: 7
                            visible: root._consoleLogs.length > 0
                            color: Qt.rgba(1,1,1,0.07)
                            Text {
                                id: logCountTxt; anchors.centerIn: parent
                                text: root._consoleLogs.length
                                color: ThemeManager.textSecondaryColor; font.pixelSize: 8; font.bold: true
                            }
                        }

                        // Error count badge
                        Rectangle {
                            id: errBadge
                            property int _errCount: {
                                var c = 0
                                for (var i = 0; i < root._consoleLogs.length; i++)
                                    if (root._consoleLogs[i].type === "err") c++
                                return c
                            }
                            height: 14; width: errBadgeTxt.implicitWidth + 10; radius: 7
                            visible: _errCount > 0
                            color: Qt.rgba(239,68,68,0.18)
                            Text {
                                id: errBadgeTxt; anchors.centerIn: parent
                                text: errBadge._errCount + " erro" + (errBadge._errCount > 1 ? "s" : "")
                                color: "#EF4444"; font.pixelSize: 8; font.bold: true
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Clear button
                        Rectangle {
                            width: 20; height: 20; radius: 4
                            visible: root._consoleLogs.length > 0
                            color: clearLogA.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            SvgIcon { anchors.centerIn: parent; width: 10; height: 10; source: Icons.close; color: ThemeManager.textSecondaryColor }
                            MouseArea {
                                id: clearLogA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root._consoleLogs = []
                            }
                        }

                        // Collapse / expand toggle
                        Rectangle {
                            width: 20; height: 20; radius: 4
                            color: colA.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: root._consoleOpen ? "▼" : "▲"
                                color: ThemeManager.textSecondaryColor; font.pixelSize: 8
                            }
                            MouseArea {
                                id: colA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root._consoleOpen = !root._consoleOpen
                            }
                        }
                    }
                }

                // Log list
                ListView {
                    id: consoleList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    visible: root._consoleOpen
                    model: root._consoleLogs
                    spacing: 0

                    onCountChanged: if (count > 0) positionViewAtBeginning()

                    // Empty state
                    Text {
                        anchors.centerIn: parent
                        visible: consoleList.count === 0
                        text: "Nenhuma saída ainda"
                        color: Qt.rgba(1,1,1,0.15); font.pixelSize: 10
                    }

                    delegate: Rectangle {
                        width: consoleList.width
                        height: logEntryText.implicitHeight + 12
                        color: modelData.type === "err"
                            ? Qt.rgba(239,68,68,0.06) : Qt.rgba(0,0,0,0)

                        // Left color strip
                        Rectangle {
                            width: 2; height: parent.height; anchors.left: parent.left
                            color: modelData.type === "err" ? "#EF4444" : "#22C55E"
                        }

                        // Bottom separator
                        Rectangle {
                            width: parent.width; height: 1
                            anchors.bottom: parent.bottom
                            color: Qt.rgba(1,1,1,0.04)
                        }

                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8; topMargin: 5; bottomMargin: 5 }
                            spacing: 8

                            // Timestamp
                            Text {
                                text: modelData.time
                                color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.family: "Consolas"
                                Layout.alignment: Qt.AlignTop
                                opacity: 0.7
                            }

                            // Event name tag
                            Rectangle {
                                height: 14; width: evTagTxt.implicitWidth + 8; radius: 3
                                color: modelData.type === "err"
                                    ? Qt.rgba(239,68,68,0.15) : Qt.rgba(34,197,94,0.12)
                                Layout.alignment: Qt.AlignTop
                                Text {
                                    id: evTagTxt; anchors.centerIn: parent
                                    text: modelData.event
                                    color: modelData.type === "err" ? "#EF4444" : "#22C55E"
                                    font.pixelSize: 8; font.bold: true
                                }
                            }

                            // Output text
                            Text {
                                id: logEntryText
                                Layout.fillWidth: true
                                text: modelData.text
                                color: modelData.type === "err"
                                    ? "#FC8181" : ThemeManager.textColor
                                font.pixelSize: 10; font.family: "Consolas"
                                wrapMode: Text.WrapAnywhere
                                opacity: modelData.type === "err" ? 1.0 : 0.9
                            }
                        }
                    }
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
