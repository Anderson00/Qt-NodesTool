import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Ctrl
import Qt.labs.platform 1.1 as Platform
import App.Theme 1.0
import App.Icons 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    // ── Debounce timer for auto-run ───────────────────────────────────────────
    Timer {
        id: _autoRunTimer
        interval: 300; repeat: false
        onTriggered: if (behaviourObject && behaviourObject.autoRun) behaviourObject.run()
    }

    // ── File Dialogs ─────────────────────────────────────────────────────────
    Platform.FileDialog {
        id: loadDialog
        title: "Load Python Script"
        nameFilters: ["Python files (*.py)", "All files (*)"]
        fileMode: Platform.FileDialog.OpenFile
        onAccepted: {
            if (behaviourObject) {
                if (behaviourObject.loadFromFile(file)) {
                    // Success
                }
            }
        }
    }

    Platform.FileDialog {
        id: saveDialog
        title: "Save Python Script"
        nameFilters: ["Python files (*.py)", "All files (*)"]
        fileMode: Platform.FileDialog.SaveFile
        onAccepted: {
            if (behaviourObject) {
                if (behaviourObject.saveToFile(file)) {
                    // Success
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // ── Top Toolbar ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 32; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.05)

            RowLayout {
                anchors.fill: parent; anchors.margins: 4; spacing: 8

                // Run Button
                Rectangle {
                    width: 70; height: 24; radius: 4
                    color: _runMa.pressed || (behaviourObject && behaviourObject.isRunning)
                           ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.3)
                           : ThemeManager.primaryColor
                    border.width: 1; border.color: Qt.darker(color, 1.2)
                    
                    RowLayout {
                        anchors.centerIn: parent; spacing: 4
                        SvgIcon {
                            width: 12; height: 12
                            source: behaviourObject && behaviourObject.isRunning ? Icons.refresh : Icons.play
                            color: ThemeManager.backgroundColor
                            RotationAnimation on rotation {
                                loops: Animation.Infinite
                                from: 0; to: 360; duration: 800
                                running: behaviourObject && behaviourObject.isRunning
                            }
                        }
                        Text { 
                            text: behaviourObject && behaviourObject.isRunning ? "RUNNING" : "RUN"
                            font.pixelSize: 10; font.bold: true; color: ThemeManager.backgroundColor 
                        }
                    }
                    MouseArea {
                        id: _runMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (behaviourObject) behaviourObject.run()
                    }
                }

                // Auto-run toggle
                Ctrl.CheckBox {
                    text: "Auto"
                    checked: behaviourObject ? behaviourObject.autoRun : false
                    onCheckedChanged: if (behaviourObject) behaviourObject.setAutoRun(checked)
                    contentItem: Text {
                        text: parent.text; font.pixelSize: 10; color: ThemeManager.textColor
                        verticalAlignment: Text.AlignVCenter; leftPadding: parent.indicator.width + parent.spacing
                    }
                }

                // Docs button
                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: _docsMa.pressed ? Qt.darker(ThemeManager.primaryColor, 1.2) : "transparent"
                    border.width: 1; border.color: ThemeManager.primaryColor
                    Text { 
                        anchors.centerIn: parent; text: "DOCS"; font.pixelSize: 10; font.bold: true
                        color: _docsMa.pressed ? ThemeManager.backgroundColor : ThemeManager.primaryColor 
                    }
                    MouseArea {
                        id: _docsMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: if (behaviourObject) behaviourObject.injectDocs()
                    }
                }

                // Save button
                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: _saveMa.pressed ? Qt.darker(ThemeManager.primaryColor, 1.2) : "transparent"
                    border.width: 1; border.color: ThemeManager.primaryColor
                    Text { 
                        anchors.centerIn: parent; text: "SAVE"; font.pixelSize: 10; font.bold: true
                        color: _saveMa.pressed ? ThemeManager.backgroundColor : ThemeManager.primaryColor 
                    }
                    MouseArea {
                        id: _saveMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: saveDialog.open()
                    }
                }

                // Load button
                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: _loadMa.pressed ? Qt.darker(ThemeManager.primaryColor, 1.2) : "transparent"
                    border.width: 1; border.color: ThemeManager.primaryColor
                    Text { 
                        anchors.centerIn: parent; text: "LOAD"; font.pixelSize: 10; font.bold: true
                        color: _loadMa.pressed ? ThemeManager.backgroundColor : ThemeManager.primaryColor 
                    }
                    MouseArea {
                        id: _loadMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: loadDialog.open()
                    }
                }

                // Timeout config
                RowLayout {
                    spacing: 2
                    Text { text: "Timeout:"; font.pixelSize: 10; color: ThemeManager.textColor }
                    Rectangle {
                        width: 40; height: 18; radius: 2
                        color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
                        border.color: ThemeManager.borderColor; border.width: 1
                        TextInput {
                            anchors.fill: parent; anchors.margins: 2
                            text: behaviourObject ? behaviourObject.timeoutMs : 5000
                            color: ThemeManager.textColor; font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            validator: IntValidator { bottom: 0; top: 999999 }
                            onEditingFinished: if (behaviourObject) behaviourObject.setTimeoutMs(parseInt(text) || 0)
                        }
                    }
                    Text { text: "ms (0=∞)"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor }
                }

                Item { Layout.fillWidth: true } // spacer

                // Status Indicator
                RowLayout {
                    spacing: 4
                    visible: behaviourObject && (behaviourObject.lastExecTime > 0 || behaviourObject.hasError)
                    SvgIcon {
                        width: 14; height: 14
                        source: behaviourObject && behaviourObject.hasError ? Icons.alertCircleOutline : Icons.checkCircleOutline
                        color: behaviourObject && behaviourObject.hasError ? "#EF4444" : "#10B981"
                    }
                    Text {
                        text: behaviourObject ? (behaviourObject.lastExecTime + "ms") : ""
                        font.pixelSize: 10; color: ThemeManager.textSecondaryColor
                        visible: !(behaviourObject && behaviourObject.hasError)
                    }
                }
            }
        }

        // ── Code Editor ───────────────────────────────────────────────────────
        CodeEditor {
            id: _editor
            Layout.fillWidth: true
            Layout.fillHeight: true
            code: behaviourObject ? behaviourObject.script : ""
            showLineNumbers: true
            
            onCodeModified: function(newCode) {
                if (behaviourObject && behaviourObject.script !== newCode) {
                    behaviourObject.setScript(newCode)
                }
            }
            onRunRequested: if (behaviourObject) behaviourObject.run()
        }

        // ── Error Message ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: _errTxt.implicitHeight + 12
            visible: behaviourObject && behaviourObject.hasError
            color: Qt.rgba(0.94, 0.27, 0.27, 0.1)
            border.color: "#EF4444"; border.width: 1; radius: 4

            Text {
                id: _errTxt
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
                text: behaviourObject ? behaviourObject.errorMsg : ""
                font.pixelSize: 10; font.family: "Consolas"
                color: "#EF4444"; wrapMode: Text.Wrap
            }
        }

        // ── Console Output (Logs) ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 60; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            border.color: ThemeManager.borderColor; border.width: 1
            visible: behaviourObject && behaviourObject.logs.length > 0

            Ctrl.ScrollView {
                anchors.fill: parent; anchors.margins: 4; clip: true
                ListView {
                    model: behaviourObject ? behaviourObject.logs : []
                    delegate: Text {
                        text: modelData
                        font.pixelSize: 10; font.family: "Consolas"
                        color: ThemeManager.textColor; opacity: 0.8
                    }
                    // Auto-scroll to bottom
                    onCountChanged: Qt.callLater(function() { positionViewAtEnd() })
                }
            }
            
            // Clear logs button
            Rectangle {
                anchors { top: parent.top; right: parent.right; margins: 4 }
                width: 16; height: 16; radius: 8
                color: _clrLog.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                SvgIcon { anchors.centerIn: parent; width: 12; height: 12; source: Icons.close; color: ThemeManager.textSecondaryColor }
                MouseArea {
                    id: _clrLog; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (behaviourObject) behaviourObject.clearLogs()
                }
            }
        }
    }
}
