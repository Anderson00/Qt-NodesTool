import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property bool autoScroll: true
    property bool showTimestamp: true
    property bool hexMode: false
    property int  lineCount: 0
    property int  byteCount: 0

    readonly property var bauds: [300,1200,2400,4800,9600,19200,38400,57600,115200,230400,460800,921600]
    property int baudIndex: 4   // 9600 default

    function appendLine(text, isRx) {
        var ts = showTimestamp ? "[" + Qt.formatTime(new Date(), "HH:mm:ss.zzz") + "] " : ""
        var prefix = isRx ? "" : "> "
        var entry  = ts + prefix + text
        logModel.append({ msg: entry, rx: isRx })
        if (logModel.count > 500) logModel.remove(0)
        lineCount++
        byteCount += text.length
        if (autoScroll) logView.positionViewAtEnd()
    }

    function clearLog() {
        logModel.clear()
        lineCount = 0
        byteCount = 0
    }

    Connections {
        target: behaviourObject
        function onInternalRxData(data) { appendLine(data, true) }
        function onInternalTxData(data) { appendLine(data, false) }
        function onInternalClear()      { clearLog() }
        function onPortChanged()        { portLabel.text = behaviourObject ? behaviourObject.port : "—" }
        function onConnectedChanged()   { /* handled by property binding */ }
    }

    ListModel { id: logModel }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 34
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 6 } spacing: 4

                // Port indicator
                Rectangle {
                    Layout.preferredHeight: 22; radius: 3
                    Layout.preferredWidth: portLabel.width + 12
                    color: behaviourObject && behaviourObject.connected
                           ? Qt.rgba(0, 0.78, 0.33, 0.15) : Qt.rgba(1, 0.09, 0.27, 0.1)
                    border.width: 1
                    border.color: behaviourObject && behaviourObject.connected ? "#00C853" : "#FF1744"

                    RowLayout {
                        anchors.centerIn: parent; spacing: 4
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: behaviourObject && behaviourObject.connected ? "#00C853" : "#FF1744"
                            SequentialAnimation on opacity {
                                running: behaviourObject && behaviourObject.connected
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.4; duration: 600 }
                                NumberAnimation { to: 1.0; duration: 600 }
                            }
                        }
                        Text {
                            id: portLabel
                            text: behaviourObject ? (behaviourObject.port || "—") : "—"
                            font.pixelSize: 10; font.family: "Consolas"
                            color: ThemeManager.textColor
                        }
                    }
                }

                // Baud rate selector
                Text { text: "Baud:"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor }
                Rectangle {
                    Layout.preferredWidth: 72; Layout.preferredHeight: 24; radius: 4
                    color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.06)
                    border.width: 1; border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)

                    RowLayout {
                        anchors.fill: parent; spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: root.bauds[root.baudIndex]
                            font.pixelSize: 9; font.family: "Consolas"
                            color: ThemeManager.textColor
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        Column {
                            spacing: 0
                            Rectangle {
                                width: 14; height: 11; radius: 2
                                color: bu.containsMouse ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2) : "transparent"
                                Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: 6; color: ThemeManager.textSecondaryColor }
                                MouseArea { id: bu; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.baudIndex = Math.min(root.bauds.length - 1, root.baudIndex + 1); if (behaviourObject) behaviourObject.setBaud(root.bauds[root.baudIndex]) } }
                            }
                            Rectangle {
                                width: 14; height: 11; radius: 2
                                color: bd.containsMouse ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2) : "transparent"
                                Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: 6; color: ThemeManager.textSecondaryColor }
                                MouseArea { id: bd; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.baudIndex = Math.max(0, root.baudIndex - 1); if (behaviourObject) behaviourObject.setBaud(root.bauds[root.baudIndex]) } }
                            }
                        }
                    }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; color: ThemeManager.borderColor; opacity: 0.5 }

                // Toggle buttons
                component Tog: Rectangle {
                    id: tog_; property string tip: ""; property string lbl: ""; property bool active: false
                    signal clicked()
                    Layout.preferredWidth: 28; Layout.preferredHeight: 26; radius: 4
                    color: tm.containsMouse ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
                                            : (active ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.14) : "transparent")
                    border.color: active ? ThemeManager.primaryColor : "transparent"; border.width: 1
                    Text { anchors.centerIn: parent; text: tog_.lbl; font.pixelSize: 10; color: tog_.active ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor }
                    AppToolTip { text: tip; visible: tm.containsMouse && tip !== ""; delay: 700 }
                    MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tog_.clicked() }
                }

                Tog { tip: "Auto Scroll"; lbl: "⬇"; active: autoScroll; onClicked: autoScroll = !autoScroll }
                Tog { tip: "Timestamps";  lbl: "⏱"; active: showTimestamp; onClicked: showTimestamp = !showTimestamp }
                Tog { tip: "HEX Mode";   lbl: "HX"; active: hexMode; onClicked: hexMode = !hexMode }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; color: ThemeManager.borderColor; opacity: 0.5 }

                Tog { tip: "Clear Log"; lbl: "✕"; onClicked: clearLog() }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.lineCount + " lines · " + root.byteCount + "B"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.family: "Consolas"
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // ── Log view ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: ThemeManager.backgroundColor

            ListView {
                id: logView
                anchors { fill: parent; margins: 4 }
                model: logModel
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 6
                }

                delegate: Text {
                    width: logView.width - 8
                    text: model.msg
                    font.pixelSize: 11; font.family: "Consolas"
                    color: model.rx ? ThemeManager.textColor : ThemeManager.primaryColor
                    wrapMode: Text.WrapAnywhere
                    opacity: model.rx ? 1.0 : 0.85
                    leftPadding: 2
                }
            }
        }

        // ── Send bar ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 38
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.9)

            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 4; bottomMargin: 4 } spacing: 4

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                    color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.05)
                    border.width: 1
                    border.color: sendField.activeFocus
                                  ? ThemeManager.primaryColor
                                  : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    TextInput {
                        id: sendField
                        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 12; font.family: "Consolas"
                        color: ThemeManager.textColor; selectionColor: ThemeManager.primaryColor
                        selectByMouse: true
                        Keys.onReturnPressed: { sendBtn.sendData(); text = "" }
                    }
                }

                // NL / CR toggle
                Rectangle {
                    Layout.preferredWidth: 32; Layout.fillHeight: true; radius: 4
                    color: nlToggle.containsMouse ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15) : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.06)
                    border.width: 1; border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                    property bool addNL: true
                    Text {
                        anchors.centerIn: parent; text: parent.addNL ? "\\n" : "raw"
                        font.pixelSize: 9; font.family: "Consolas"; color: ThemeManager.textSecondaryColor
                    }
                    MouseArea { id: nlToggle; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.addNL = !parent.addNL }
                }

                NewButton {
                    id: sendBtn
                    Layout.preferredWidth: 52; Layout.fillHeight: true
                    variant: "filled"; text: "Send"
                    backgroundColor: ThemeManager.primaryColor
                    function sendData() {
                        var txt = sendField.text
                        if (txt === "") return
                        if (behaviourObject) behaviourObject.sendData(txt)
                        appendLine(txt, false)
                        sendField.text = ""
                    }
                    onClicked: sendData()
                }
            }
        }
    }
}

