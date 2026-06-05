import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick 2.15
import QtQml 2.15



import App.Theme 1.0
import App.Icons 1.0

import '../'

Drawer {
    id: root

    property QtObject viewPortWindow
    property var selectedObjectView

    width: 280
    height: parent.height
    modal: false
    edge: Qt.RightEdge
    interactive: false
    visible: selectedObjectView !== null && selectedObjectView !== undefined

    background: Rectangle {
        color: Qt.rgba(ThemeManager.surfaceColor.r,
                      ThemeManager.surfaceColor.g,
                      ThemeManager.surfaceColor.b, 0.15)
        border.width: 1
        border.color: Qt.rgba(ThemeManager.primaryColor.r,
                             ThemeManager.primaryColor.g,
                             ThemeManager.primaryColor.b, 0.2)
    }

    property string currentNodeUuid: ""

    // World-coordinate offset — nodes live in 0..10000 canvas space and the
    // panel displays them relative to the canvas centre (5000, 5000).
    readonly property real worldOrigin: 5000

    onSelectedObjectViewChanged: {
        if (selectedObjectView) {
            updateConnectionsList()
        }
    }

    function updateConnectionsList() {
        if (selectedObjectView && selectedObjectView.behaviourObject && viewPortWindow) {
            currentNodeUuid = selectedObjectView.behaviourObject.uuid;
            var conns = viewPortWindow.getNodeConnections(currentNodeUuid);
            connsListView.model = conns;
        } else {
            currentNodeUuid = "";
            connsListView.model = []
        }
    }

    function clamp(value, min, max) {
        return Math.max(min, Math.min(max, value))
    }

    // ── Geometry commit helpers ─────────────────────────────────────────────
    // Both push a single QUndoCommand so the change is reversible from the
    // history panel and via Ctrl+Z. Values entered in the panel are in the
    // "relative-to-centre" world space the user sees on screen.
    function commitPositionEdit(newRelX, newRelY) {
        if (!selectedObjectView || !viewPortWindow || currentNodeUuid === "") return
        var oldX = selectedObjectView.x
        var oldY = selectedObjectView.y
        var nx = newRelX + worldOrigin
        var ny = newRelY + worldOrigin
        if (Math.abs(nx - oldX) < 0.5 && Math.abs(ny - oldY) < 0.5) return
        selectedObjectView.x = nx
        selectedObjectView.y = ny
        viewPortWindow.recordNodeMove(currentNodeUuid, oldX, oldY, nx, ny)
    }

    function commitSizeEdit(newW, newH) {
        if (!selectedObjectView || !viewPortWindow || currentNodeUuid === "") return
        var oldX = selectedObjectView.x
        var oldY = selectedObjectView.y
        var oldW = selectedObjectView.width
        var oldH = selectedObjectView.height
        var nw = Math.max(selectedObjectView.minWidth  || 50, newW)
        var nh = Math.max(selectedObjectView.minHeight || 50, newH)
        if (Math.abs(nw - oldW) < 0.5 && Math.abs(nh - oldH) < 0.5) return
        selectedObjectView.width  = nw
        selectedObjectView.height = nh
        viewPortWindow.recordNodeResize(currentNodeUuid,
                                        oldX, oldY, oldW, oldH,
                                        oldX, oldY, nw,   nh)
    }

    Connections {
        target: viewPortWindow
        function onConnectionAdded(outU, outM, inU, inM) { updateConnectionsList() }
        function onConnectionRemoved(outU, outM, inU, inM) { updateConnectionsList() }
    }

    // ── Inline-editable numeric field ───────────────────────────────────────
    // Click the value → it becomes a TextInput; Enter or focus-loss commits,
    // Escape cancels. Used for x, y, width, height and opacity.
    //
    // CRITICAL: `field.value` is a one-way input bound by the caller to the
    // node's live property. We MUST NEVER assign to it from inside this
    // component or QML will tear down the caller's binding and freeze the
    // displayed value (real bug that hit x/y/width/height during dragging).
    // The display Text is bound directly to `field.value`; the TextInput
    // keeps its own buffer and only mirrors `field.value` while editing.
    component InlineNumberField : Item {
        id: field

        property string label: ""
        property real   value: 0
        property real   min:   -1e9
        property real   max:    1e9
        property int    decimals: 0
        property color  accentColor: ThemeManager.primaryColor
        property color  containerColor: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.08)
        property color  containerBorder: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)

        signal commit(real newValue)

        implicitHeight: 50

        Rectangle {
            id: container
            anchors.fill: parent
            radius: 4
            color: field.containerColor
            border.width: 1
            border.color: editor.activeFocus ? field.accentColor : field.containerBorder
            Behavior on border.color { ColorAnimation { duration: 120 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 3

                Text {
                    text: field.label
                    font.pixelSize: 9
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        id: display
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        // Bound directly to the source via field.value — keeps
                        // updating in real-time while the node is dragged.
                        text: field.value.toFixed(field.decimals)
                        font.pixelSize: 16
                        font.bold: true
                        color: field.accentColor
                        visible: !editor.activeFocus
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 100 } }
                    }

                    TextInput {
                        id: editor
                        anchors.fill: parent
                        verticalAlignment: TextInput.AlignVCenter
                        // No binding here: the buffer is seeded on focus-in
                        // and cleared on focus-out. This prevents QML from
                        // ever evaluating `text` as an expression that could
                        // be lost when we assign to it during edit/commit.
                        text: ""
                        font.pixelSize: 16
                        font.bold: true
                        color: field.accentColor
                        selectionColor: Qt.rgba(field.accentColor.r, field.accentColor.g, field.accentColor.b, 0.35)
                        selectedTextColor: ThemeManager.textColor
                        clip: true
                        visible: activeFocus
                        opacity: visible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 100 } }

                        validator: DoubleValidator {
                            bottom: field.min
                            top:    field.max
                            notation: DoubleValidator.StandardNotation
                            decimals: Math.max(0, field.decimals)
                            locale: "C"
                        }

                        property bool _cancelling: false

                        function _doCommit() {
                            var v = parseFloat(text.replace(",", "."))
                            if (isNaN(v)) { return }
                            v = Math.max(field.min, Math.min(field.max, v))
                            // IMPORTANT: do NOT assign to field.value here —
                            // that would destroy the caller's binding to the
                            // node's live property. Just emit commit() and
                            // the display Text will refresh automatically.
                            field.commit(v)
                        }

                        Keys.onPressed: function(ev) {
                            if (ev.key === Qt.Key_Escape) {
                                _cancelling = true
                                focus = false
                                ev.accepted = true
                            } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
                                _doCommit()
                                focus = false
                                ev.accepted = true
                            }
                        }

                        onActiveFocusChanged: {
                            if (activeFocus) {
                                // Seed the editor buffer from the live value.
                                text = field.value.toFixed(field.decimals)
                                selectAll()
                            } else {
                                if (!_cancelling) _doCommit()
                                _cancelling = false
                                // Clear so the next focus-in always reseeds
                                // from field.value (no stale buffer).
                                text = ""
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        visible: !editor.activeFocus
                        onClicked: { editor.forceActiveFocus(); editor.selectAll() }
                    }
                }
            }
        }
    }

    // ── Inline-editable text field (used for node title rename) ─────────────
    // Same binding-safety contract as InlineNumberField: never assign to
    // `tField.value` from inside this component.
    component InlineTextField : Item {
        id: tField

        property string value: ""
        property color  textColor: ThemeManager.primaryColor

        signal commit(string newValue)

        implicitHeight: 22

        Text {
            id: tDisplay
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            text: tField.value
            font.pixelSize: 14
            font.bold: true
            color: tField.textColor
            elide: Text.ElideRight
            visible: !tEditor.activeFocus
        }

        TextInput {
            id: tEditor
            anchors.fill: parent
            verticalAlignment: TextInput.AlignVCenter
            text: ""
            font.pixelSize: 14
            font.bold: true
            color: tField.textColor
            selectionColor: Qt.rgba(tField.textColor.r, tField.textColor.g, tField.textColor.b, 0.35)
            clip: true
            visible: activeFocus

            property bool _cancelling: false

            function _doCommit() {
                var t = text.trim()
                if (t === "" || t === tField.value) return
                tField.commit(t)
            }

            Keys.onPressed: function(ev) {
                if (ev.key === Qt.Key_Escape) {
                    _cancelling = true
                    focus = false
                    ev.accepted = true
                } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
                    _doCommit()
                    focus = false
                    ev.accepted = true
                }
            }

            onActiveFocusChanged: {
                if (activeFocus) {
                    text = tField.value
                    selectAll()
                } else {
                    if (!_cancelling) _doCommit()
                    _cancelling = false
                    text = ""
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            visible: !tEditor.activeFocus
            onClicked: { tEditor.forceActiveFocus(); tEditor.selectAll() }
        }
    }

    // ── Small icon-button used in the action row ────────────────────────────
    component IconActionButton : Rectangle {
        id: btn
        property url iconSource
        property color accentColor: ThemeManager.primaryColor
        property bool toggled: false
        property string tip: ""

        signal clicked()

        implicitWidth: 36
        implicitHeight: 32
        radius: 4
        color: toggled
               ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.25)
               : (mouse.containsMouse
                  ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.12)
                  : "transparent")
        border.width: 1
        border.color: toggled
                      ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.5)
                      : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.2)
        Behavior on color { ColorAnimation { duration: 120 } }

        ColorIcon {
            anchors.centerIn: parent
            width: 16; height: 16
            source: btn.iconSource
            color: btn.accentColor
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }

        AppToolTip {
            visible: mouse.containsMouse && btn.tip !== ""
            text: btn.tip
            delay: 400
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
        width: root.width - 24
        x: 12
        y: 12
        spacing: 12

        // ── Header: node name (editable) + UUID ─────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            radius: 8
            color: Qt.rgba(ThemeManager.primaryColor.r,
                          ThemeManager.primaryColor.g,
                          ThemeManager.primaryColor.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                 ThemeManager.primaryColor.g,
                                 ThemeManager.primaryColor.b, 0.3)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: qsTr("Selected Node")
                        font.pixelSize: 10
                        font.bold: true
                        color: ThemeManager.textSecondaryColor
                        opacity: 0.7
                        Layout.fillWidth: true
                    }

                    ColorIcon {
                        width: 11; height: 11
                        source: Icons.pencilOutline
                        color: ThemeManager.textSecondaryColor
                        opacity: 0.5
                    }
                }

                InlineTextField {
                    id: nameField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    value: selectedObjectView && selectedObjectView.behaviourObject
                           ? selectedObjectView.behaviourObject.title
                           : ""
                    onCommit: function(newValue) {
                        if (selectedObjectView && selectedObjectView.behaviourObject)
                            selectedObjectView.behaviourObject.title = newValue
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                   ThemeManager.primaryColor.g,
                                   ThemeManager.primaryColor.b, 0.2)
                }

                Text {
                    text: selectedObjectView
                          ? selectedObjectView.behaviourObject.uuid
                          : ""
                    font.pixelSize: 9
                    font.family: "Courier New"
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.55
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // ── Quick actions row ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 4

                IconActionButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 32
                    iconSource: (selectedObjectView && selectedObjectView.userLocked)
                                ? Icons.lock : Icons.lockOpenOutline
                    toggled: selectedObjectView && selectedObjectView.userLocked
                    accentColor: ThemeManager.warningColor
                    tip: qsTr("Lock position and size")
                    onClicked: {
                        if (!selectedObjectView) return
                        selectedObjectView.userLocked = !selectedObjectView.userLocked
                    }
                }

                IconActionButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 32
                    iconSource: (selectedObjectView && selectedObjectView.userHidden)
                                ? Icons.eyeOffOutline : Icons.eye
                    toggled: selectedObjectView && selectedObjectView.userHidden
                    accentColor: ThemeManager.dangerColor
                    tip: qsTr("Hide on canvas")
                    onClicked: {
                        if (!selectedObjectView) return
                        selectedObjectView.userHidden = !selectedObjectView.userHidden
                    }
                }

                IconActionButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 32
                    iconSource: Icons.palette
                    accentColor: ThemeManager.secondaryColor
                    tip: qsTr("Open color override")
                    onClicked: colorPopup.open()
                }

                Item { Layout.fillWidth: true }

                IconActionButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 32
                    iconSource: Icons.contentSaveOutline
                    accentColor: ThemeManager.primaryColor
                    tip: qsTr("Duplicate node")
                    onClicked: {
                        if (!viewPortWindow || currentNodeUuid === "") return
                        var data = viewPortWindow.getNodeData(currentNodeUuid)
                        if (data) viewPortWindow.pasteNode(data, 24, 24)
                    }
                }
            }
        }

        // ── Position section (editable) ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: qsTr("Position (relative to center)")
                    font.pixelSize: 11
                    font.bold: true
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    InlineNumberField {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        label: qsTr("X")
                        decimals: 0
                        accentColor: ThemeManager.primaryColor
                        value: selectedObjectView ? selectedObjectView.x - worldOrigin : 0
                        onCommit: function(v) {
                            commitPositionEdit(v, selectedObjectView ? selectedObjectView.y - worldOrigin : 0)
                        }
                    }

                    InlineNumberField {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        label: qsTr("Y")
                        decimals: 0
                        accentColor: ThemeManager.primaryColor
                        value: selectedObjectView ? selectedObjectView.y - worldOrigin : 0
                        onCommit: function(v) {
                            commitPositionEdit(selectedObjectView ? selectedObjectView.x - worldOrigin : 0, v)
                        }
                    }
                }
            }
        }

        // ── Size section (editable) ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 90
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: qsTr("Size")
                    font.pixelSize: 11
                    font.bold: true
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    InlineNumberField {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        label: qsTr("Width")
                        decimals: 0
                        min: 50
                        max: 4000
                        accentColor: ThemeManager.successColor
                        value: selectedObjectView ? selectedObjectView.width : 0
                        onCommit: function(v) {
                            commitSizeEdit(v, selectedObjectView ? selectedObjectView.height : 0)
                        }
                    }

                    InlineNumberField {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        label: qsTr("Height")
                        decimals: 0
                        min: 50
                        max: 4000
                        accentColor: ThemeManager.successColor
                        value: selectedObjectView ? selectedObjectView.height : 0
                        onCommit: function(v) {
                            commitSizeEdit(selectedObjectView ? selectedObjectView.width : 0, v)
                        }
                    }
                }
            }
        }

        // ── Opacity slider ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("Opacity")
                        font.pixelSize: 11
                        font.bold: true
                        color: ThemeManager.textSecondaryColor
                        opacity: 0.7
                        Layout.fillWidth: true
                    }
                    Text {
                        text: selectedObjectView
                              ? Math.round(selectedObjectView.userOpacity * 100) + "%"
                              : "100%"
                        font.pixelSize: 11
                        font.bold: true
                        color: ThemeManager.primaryColor
                    }
                }

                Slider {
                    Layout.fillWidth: true
                    from: 0.1
                    to:   1.0
                    stepSize: 0.01
                    value: selectedObjectView ? selectedObjectView.userOpacity : 1.0
                    onMoved: {
                        if (selectedObjectView) selectedObjectView.userOpacity = value
                    }
                }
            }
        }

        // ── Z-index section ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 6
            color: Qt.rgba(ThemeManager.warningColor.r,
                          ThemeManager.warningColor.g,
                          ThemeManager.warningColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.warningColor.r,
                                 ThemeManager.warningColor.g,
                                 ThemeManager.warningColor.b, 0.2)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: qsTr("Z-Index (Layer)")
                        font.pixelSize: 10
                        font.bold: true
                        color: ThemeManager.textSecondaryColor
                        opacity: 0.6
                    }

                    Text {
                        text: selectedObjectView ? selectedObjectView.z : "0"
                        font.pixelSize: 12
                        font.bold: true
                        color: ThemeManager.warningColor
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 28
                    radius: 4
                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                  ThemeManager.primaryColor.g,
                                  ThemeManager.primaryColor.b, 0.2)

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Front")
                        font.pixelSize: 10
                        color: ThemeManager.textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (selectedObjectView) selectedObjectView.z += 1
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 28
                    radius: 4
                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                  ThemeManager.primaryColor.g,
                                  ThemeManager.primaryColor.b, 0.2)

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Back")
                        font.pixelSize: 10
                        color: ThemeManager.textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (selectedObjectView) selectedObjectView.z = Math.max(0, selectedObjectView.z - 1)
                    }
                }
            }
        }

        // ── Connections section ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: qsTr("Connections")
                    font.pixelSize: 11
                    font.bold: true
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                ListView {
                    id: connsListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: []
                    ScrollBar.vertical: ScrollBar {}

                    delegate: Rectangle {
                        width: connsListView.width
                        height: 46
                        radius: 4
                        color: Qt.rgba(ThemeManager.surfaceColor.r,
                                      ThemeManager.surfaceColor.g,
                                      ThemeManager.surfaceColor.b, 0.4)
                        border.width: 1
                        border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                             ThemeManager.primaryColor.g,
                                             ThemeManager.primaryColor.b, 0.2)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 4

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: {
                                        var isOutput = (modelData.outputUuid === root.currentNodeUuid);
                                        var dir = isOutput ? qsTr("=> Destination") : qsTr("<= Origin");
                                        return dir + " (" + (isOutput ? modelData.inputMethod : modelData.outputMethod) + ")"
                                    }
                                    font.pixelSize: 10
                                    color: ThemeManager.textColor
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: qsTr("M: ") + (modelData.outputUuid === root.currentNodeUuid ? modelData.outputMethod : modelData.inputMethod)
                                    font.pixelSize: 9
                                    color: ThemeManager.textSecondaryColor
                                    opacity: 0.8
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 4
                                color: "transparent"
                                ColorIcon {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: Icons.fileDocumentEditOutline
                                    color: ThemeManager.textColor
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var cmt = viewPortWindow.getConnectionComment(modelData.outputUuid, modelData.outputMethod, modelData.inputUuid, modelData.inputMethod);
                                        var msg = cmt ? cmt : qsTr("No annotation.");
                                        ToastManager.show(qsTr("Comment: ") + msg, "info");
                                    }
                                    onEntered: parent.color = Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15)
                                    onExited: parent.color = "transparent"
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 4
                                color: "transparent"
                                ColorIcon {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: Icons.viewWeek
                                    color: ThemeManager.textColor
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ToastManager.show(qsTr("Value interception requires the Debugger node (Coming soon)"), "warning")
                                    onEntered: parent.color = Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15)
                                    onExited: parent.color = "transparent"
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: 4
                                color: "transparent"
                                ColorIcon {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: Icons.close
                                    color: ThemeManager.dangerColor
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: viewPortWindow.removeConnectionWithUndo(modelData.outputUuid, modelData.outputMethod, modelData.inputUuid, modelData.inputMethod)
                                    onEntered: parent.color = Qt.rgba(ThemeManager.dangerColor.r, ThemeManager.dangerColor.g, ThemeManager.dangerColor.b, 0.2)
                                    onExited: parent.color = "transparent"
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Presentation section ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Text {
                    text: qsTr("Presentation")
                    font.pixelSize: 11
                    font.bold: true
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: qsTr("Hide in presentation mode")
                        font.pixelSize: 11
                        color: ThemeManager.textColor
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        id: hideToggle
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 18
                        radius: 9
                        readonly property bool active:
                            selectedObjectView !== null && selectedObjectView !== undefined
                            && selectedObjectView.behaviourObject
                            && selectedObjectView.behaviourObject.hiddenInPresentation
                        color: active
                               ? Qt.rgba(ThemeManager.primaryColor.r,
                                         ThemeManager.primaryColor.g,
                                         ThemeManager.primaryColor.b, 0.8)
                               : Qt.rgba(ThemeManager.borderColor.r,
                                         ThemeManager.borderColor.g,
                                         ThemeManager.borderColor.b, 0.5)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            width: 14; height: 14; radius: 7
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            x: hideToggle.active ? parent.width - width - 2 : 2
                            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!selectedObjectView || !selectedObjectView.behaviourObject) return
                                selectedObjectView.behaviourObject.hiddenInPresentation =
                                    !selectedObjectView.behaviourObject.hiddenInPresentation
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 4 }

        // ── Delete node button ──────────────────────────────────────────────
        Rectangle {
            id: deleteBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            radius: 6
            color: Qt.rgba(ThemeManager.dangerColor.r,
                           ThemeManager.dangerColor.g,
                           ThemeManager.dangerColor.b,
                           deleteMouse.containsMouse ? 0.18 : 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.dangerColor.r,
                                  ThemeManager.dangerColor.g,
                                  ThemeManager.dangerColor.b, 0.3)

            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 8

                ColorIcon {
                    source: Icons.deleteOutline
                    color: ThemeManager.dangerColor
                    width: 16; height: 16
                }

                Text {
                    text: qsTr("Delete Node")
                    font.pixelSize: 12
                    font.bold: true
                    color: ThemeManager.dangerColor
                    Layout.fillWidth: true
                }
            }

            MouseArea {
                id: deleteMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (viewPortWindow && currentNodeUuid !== "")
                        viewPortWindow.removeNodeWithUndo(currentNodeUuid)
                }
            }
        }
    }
    } // end ScrollView

    // ── Color override popup ────────────────────────────────────────────────
    // Lets the user pick a custom header colour for the node. Falls back to
    // the global theme value when reset. The popup is intentionally a child
    // of the Drawer (root) so it overlays both the canvas and the panel.
    Popup {
        id: colorPopup
        parent: Overlay.overlay
        x: Overlay.overlay ? (Overlay.overlay.width - width) / 2 : 0
        y: Overlay.overlay ? (Overlay.overlay.height - height) / 2 : 0
        width: 320
        height: 240
        modal: true
        focus: true
        padding: 0
        z: 10000
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: ThemeManager.backgroundColor
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: qsTr("Color Override")
                font.pixelSize: 13
                font.bold: true
                color: ThemeManager.textColor
            }

            ColorPicker {
                id: headerPicker
                Layout.fillWidth: true
                label: qsTr("Header")
                value: (selectedObjectView && selectedObjectView.behaviourObject
                        && selectedObjectView.behaviourObject.nodeTheme)
                       ? selectedObjectView.behaviourObject.nodeTheme.headerColor
                       : ThemeManager.primaryColor
                onAccepted: function(c) {
                    if (selectedObjectView && selectedObjectView.behaviourObject
                            && selectedObjectView.behaviourObject.nodeTheme) {
                        selectedObjectView.behaviourObject.nodeTheme.headerColor = c
                    }
                }
            }

            ColorPicker {
                id: borderPicker
                Layout.fillWidth: true
                label: qsTr("Border")
                value: (selectedObjectView && selectedObjectView.behaviourObject
                        && selectedObjectView.behaviourObject.nodeTheme)
                       ? selectedObjectView.behaviourObject.nodeTheme.borderColor
                       : ThemeManager.primaryColor
                onAccepted: function(c) {
                    if (selectedObjectView && selectedObjectView.behaviourObject
                            && selectedObjectView.behaviourObject.nodeTheme) {
                        selectedObjectView.behaviourObject.nodeTheme.borderColor = c
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 4
                    color: resetMouse.containsMouse
                           ? Qt.rgba(ThemeManager.warningColor.r,
                                     ThemeManager.warningColor.g,
                                     ThemeManager.warningColor.b, 0.18)
                           : Qt.rgba(ThemeManager.warningColor.r,
                                     ThemeManager.warningColor.g,
                                     ThemeManager.warningColor.b, 0.08)
                    border.width: 1
                    border.color: Qt.rgba(ThemeManager.warningColor.r,
                                          ThemeManager.warningColor.g,
                                          ThemeManager.warningColor.b, 0.3)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Reset to theme")
                        font.pixelSize: 11
                        font.bold: true
                        color: ThemeManager.warningColor
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (selectedObjectView && selectedObjectView.behaviourObject
                                    && selectedObjectView.behaviourObject.nodeTheme) {
                                selectedObjectView.behaviourObject.nodeTheme.resetAllColors()
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 4
                    color: closeMouse.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r,
                                     ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.25)
                           : Qt.rgba(ThemeManager.primaryColor.r,
                                     ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.15)
                    border.width: 1
                    border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                          ThemeManager.primaryColor.g,
                                          ThemeManager.primaryColor.b, 0.4)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Close")
                        font.pixelSize: 11
                        font.bold: true
                        color: ThemeManager.primaryColor
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: colorPopup.close()
                    }
                }
            }
        }
    }
}
