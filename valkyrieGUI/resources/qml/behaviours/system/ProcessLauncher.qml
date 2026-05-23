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

    property string stdoutLog:  ""
    property string stderrLog:  ""
    property int    lastExit:   -1
    property bool   running:    false

    Connections {
        target: behaviourObject
        function onInternalStdout(text)     { stdoutLog  += text }
        function onInternalStderr(text)     { stderrLog  += text }
        function onInternalFinished(code)   { lastExit = code; running = false }
        function onInternalStarted()        { running = true; stdoutLog = ""; stderrLog = "" }
        function onIsRunningChanged()       { if (behaviourObject) running = behaviourObject.isRunning }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Title ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "Process Launcher"
                color: ThemeManager.textColor
                font.pixelSize: 11
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 8; height: 8; radius: 4
                color: running ? "#2ecc71" : ThemeManager.borderColor
            }
            Text {
                text: running ? "Running (PID " + (behaviourObject ? behaviourObject.pid : 0) + ")" : "Idle"
                color: running ? "#2ecc71" : ThemeManager.textSecondaryColor
                font.pixelSize: 9
            }
        }

        // ── Command field ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: "Cmd:"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
                Layout.alignment: Qt.AlignVCenter
            }
            CustomTextField {
                id: cmdField
                Layout.fillWidth: true
                placeholderText: "command / executable"
            }
        }

        // ── Args field ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: "Args:"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
                Layout.alignment: Qt.AlignVCenter
            }
            CustomTextField {
                id: argsField
                Layout.fillWidth: true
                placeholderText: "arg1, arg2, ... (comma-separated)"
            }
        }

        // ── Working dir field ─────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: "Dir:"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
                Layout.alignment: Qt.AlignVCenter
            }
            CustomTextField {
                id: wdirField
                Layout.fillWidth: true
                placeholderText: "working directory (optional)"
                text: behaviourObject ? behaviourObject.workingDir : ""
                onTextChanged: {
                    if (behaviourObject) behaviourObject.workingDir = text
                }
            }
        }

        // ── Launch / Kill ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                variant: "filled"
                text: "Launch"
                backgroundColor: ThemeManager.primaryColor
                enabled: !running
                onClicked: {
                    if (!behaviourObject) return
                    var cmd = cmdField.text.trim()
                    if (cmd === "") return
                    var argsRaw = argsField.text.trim()
                    if (argsRaw === "") {
                        behaviourObject.launchShell(cmd)
                    } else {
                        var argList = argsRaw.split(",").map(function(s) { return s.trim() })
                        behaviourObject.launch(cmd, argList)
                    }
                }
            }

            NewButton {
                Layout.preferredWidth: 60
                Layout.preferredHeight: 28
                variant: "filled"
                text: "Kill"
                backgroundColor: "#e74c3c"
                enabled: running
                onClicked: { if (behaviourObject) behaviourObject.kill() }
            }

            // Exit code badge
            Rectangle {
                visible: lastExit >= 0
                width: exitLabel.implicitWidth + 16
                height: 28; radius: 14
                color: lastExit === 0
                       ? Qt.rgba(0.18, 0.8, 0.44, 0.15)
                       : Qt.rgba(0.93, 0.17, 0.17, 0.15)
                border.width: 1
                border.color: lastExit === 0 ? "#2ecc71" : "#e74c3c"

                Text {
                    id: exitLabel
                    anchors.centerIn: parent
                    text: "exit: " + lastExit
                    color: lastExit === 0 ? "#2ecc71" : "#e74c3c"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }

        // ── Stdout log ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 40
            color: "#1a1a1a"
            radius: 3
            clip: true

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 2
                spacing: 0

                Text {
                    text: "stdout"
                    color: "#888"
                    font.pixelSize: 8
                    font.bold: true
                    leftPadding: 4
                    topPadding: 2
                }
            }

            Flickable {
                id: stdoutFlick
                anchors.fill: parent
                anchors.topMargin: 14
                anchors.margins: 4
                contentWidth: width
                contentHeight: stdoutText.contentHeight
                clip: true

                onContentHeightChanged: {
                    if (contentHeight > height)
                        contentY = contentHeight - height
                }

                Text {
                    id: stdoutText
                    width: stdoutFlick.width
                    text: stdoutLog === "" ? "(no output)" : stdoutLog
                    color: stdoutLog === "" ? "#555" : "#d4d4d4"
                    font.family: "Consolas, monospace"
                    font.pixelSize: 9
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // ── Stderr log ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: "#1a1010"
            radius: 3
            clip: true
            visible: stderrLog !== ""

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: 2
                spacing: 0
                Text {
                    text: "stderr"
                    color: "#c0392b"
                    font.pixelSize: 8
                    font.bold: true
                    leftPadding: 4
                    topPadding: 2
                }
            }

            Flickable {
                id: stderrFlick
                anchors.fill: parent
                anchors.topMargin: 14
                anchors.margins: 4
                contentWidth: width
                contentHeight: stderrText.contentHeight
                clip: true

                onContentHeightChanged: {
                    if (contentHeight > height)
                        contentY = contentHeight - height
                }

                Text {
                    id: stderrText
                    width: stderrFlick.width
                    text: stderrLog
                    color: "#e74c3c"
                    font.family: "Consolas, monospace"
                    font.pixelSize: 9
                    wrapMode: Text.WrapAnywhere
                }
            }
        }
    }
}
