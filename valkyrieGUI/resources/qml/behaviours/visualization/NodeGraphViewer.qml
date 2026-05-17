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

    property var nodes: ({})
    property var edges: []
    property string selectedLayout: "force"

    // Force simulation state
    property bool simRunning: false

    Connections {
        target: behaviourObject
        function onInternalGraphChanged() { syncGraph() }
        function onInternalClear() { nodes = {}; edges = []; canvas.requestPaint() }
        function onLayoutChanged() {
            if (behaviourObject) selectedLayout = behaviourObject.layout
        }
    }

    function syncGraph() {
        if (!behaviourObject) return
        nodes          = behaviourObject.getNodes()
        edges          = behaviourObject.getEdges()
        selectedLayout = behaviourObject.layout
        canvas.requestPaint()
    }

    Component.onCompleted: syncGraph()

    // Force-directed simulation timer
    Timer {
        id: forceTimer
        interval: 33
        repeat: true
        running: root.simRunning && root.selectedLayout === "force"

        onTriggered: {
            var nodeIds = Object.keys(nodes)
            var n = nodeIds.length
            if (n === 0) return

            var W = canvas.width
            var H = canvas.height

            // Copy positions for calculation
            var pos = {}
            for (var i = 0; i < n; i++) {
                var id = nodeIds[i]
                pos[id] = { x: nodes[id].x, y: nodes[id].y,
                            dx: 0, dy: 0, pinned: nodes[id].pinned }
            }

            // Repulsion (Coulomb)
            var repK = 3000
            for (var a = 0; a < n; a++) {
                for (var b = a + 1; b < n; b++) {
                    var ia = nodeIds[a], ib = nodeIds[b]
                    var dx = pos[ia].x - pos[ib].x
                    var dy = pos[ia].y - pos[ib].y
                    var dist = Math.sqrt(dx*dx + dy*dy) || 1
                    var force = repK / (dist * dist)
                    var fx = force * dx / dist
                    var fy = force * dy / dist
                    pos[ia].dx += fx; pos[ia].dy += fy
                    pos[ib].dx -= fx; pos[ib].dy -= fy
                }
            }

            // Spring (Hooke) along edges
            var springK = 0.04, restLen = 90
            for (var ei = 0; ei < edges.length; ei++) {
                var from = edges[ei].from, to = edges[ei].to
                if (!pos[from] || !pos[to]) continue
                var ex = pos[to].x - pos[from].x
                var ey = pos[to].y - pos[from].y
                var eDist = Math.sqrt(ex*ex + ey*ey) || 1
                var stretch = eDist - restLen
                var sfx = springK * stretch * ex / eDist
                var sfy = springK * stretch * ey / eDist
                pos[from].dx += sfx; pos[from].dy += sfy
                pos[to].dx   -= sfx; pos[to].dy   -= sfy
            }

            // Apply with damping
            var newNodes = JSON.parse(JSON.stringify(nodes))
            var damping = 0.85
            for (var j = 0; j < n; j++) {
                var jid = nodeIds[j]
                if (pos[jid].pinned) continue
                var nx = pos[jid].x + pos[jid].dx * damping
                var ny = pos[jid].y + pos[jid].dy * damping
                // Clamp to canvas
                nx = Math.max(30, Math.min(W - 30, nx))
                ny = Math.max(20, Math.min(H - 20, ny))
                newNodes[jid].x = nx
                newNodes[jid].y = ny
                if (behaviourObject)
                    behaviourObject.setNodePos(jid, nx, ny)
            }
            nodes = newNodes
            canvas.requestPaint()
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header toolbar
        Rectangle {
            Layout.fillWidth: true
            height: 32
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "Node Graph"
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Object.keys(nodes).length + "N / " + edges.length + "E"
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignVCenter
                }

                CustomComboBox {
                    id: layoutCombo
                    Layout.preferredWidth: 90
                    model: ["force", "circular", "tree"]
                    currentIndex: ["force","circular","tree"].indexOf(selectedLayout)
                    onCurrentTextChanged: {
                        if (behaviourObject) {
                            behaviourObject.setLayout(currentText)
                            behaviourObject.applyLayout()
                        }
                        selectedLayout = currentText
                        root.simRunning = (currentText === "force")
                    }
                }

                NewButton {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 24
                    variant: root.simRunning ? "filled" : "outlined"
                    label: root.simRunning ? "Pause" : "Run"
                    backgroundColor: root.simRunning ? ThemeManager.primaryColor : "transparent"
                    onClicked: root.simRunning = !root.simRunning
                }
            }
        }

        // Canvas
        Canvas {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true

            property var dragId: null
            property real dragOffX: 0
            property real dragOffY: 0

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                // Background
                ctx.fillStyle = Qt.rgba(
                    ThemeManager.backgroundColor.r,
                    ThemeManager.backgroundColor.g,
                    ThemeManager.backgroundColor.b, 1)
                ctx.fillRect(0, 0, width, height)

                var nodeIds = Object.keys(nodes)

                // Edges
                for (var ei = 0; ei < edges.length; ei++) {
                    var edge = edges[ei]
                    var fn = nodes[edge.from], tn = nodes[edge.to]
                    if (!fn || !tn) continue

                    var fx = fn.x, fy = fn.y, tx = tn.x, ty = tn.y
                    var angle = Math.atan2(ty - fy, tx - fx)
                    var nodeR = 20

                    ctx.strokeStyle = Qt.rgba(
                        ThemeManager.borderColor.r,
                        ThemeManager.borderColor.g,
                        ThemeManager.borderColor.b, 0.8)
                    ctx.lineWidth = 1.5
                    ctx.beginPath()
                    ctx.moveTo(fx, fy)
                    ctx.lineTo(tx, ty)
                    ctx.stroke()

                    // Arrowhead
                    var arrowLen = 8, arrowAngle = 0.4
                    var ex2 = tx - nodeR * Math.cos(angle)
                    var ey2 = ty - nodeR * Math.sin(angle)
                    ctx.beginPath()
                    ctx.moveTo(ex2, ey2)
                    ctx.lineTo(ex2 - arrowLen * Math.cos(angle - arrowAngle),
                               ey2 - arrowLen * Math.sin(angle - arrowAngle))
                    ctx.lineTo(ex2 - arrowLen * Math.cos(angle + arrowAngle),
                               ey2 - arrowLen * Math.sin(angle + arrowAngle))
                    ctx.closePath()
                    ctx.fillStyle = ThemeManager.borderColor
                    ctx.fill()

                    // Edge label
                    if (edge.label && edge.label !== "") {
                        ctx.fillStyle = ThemeManager.textSecondaryColor
                        ctx.font = "8px sans-serif"
                        ctx.textAlign = "center"
                        ctx.fillText(edge.label, (fx + tx) / 2, (fy + ty) / 2 - 4)
                    }
                }

                // Nodes
                for (var ni = 0; ni < nodeIds.length; ni++) {
                    var nid = nodeIds[ni]
                    var node = nodes[nid]
                    var nx = node.x, ny = node.y
                    var isPinned = node.pinned

                    // Shadow
                    ctx.shadowColor = "rgba(0,0,0,0.3)"
                    ctx.shadowBlur  = 4

                    // Node circle
                    ctx.beginPath()
                    ctx.arc(nx, ny, 20, 0, 2 * Math.PI)
                    if (isPinned) {
                        ctx.fillStyle = Qt.rgba(
                            ThemeManager.primaryColor.r,
                            ThemeManager.primaryColor.g,
                            ThemeManager.primaryColor.b, 0.9)
                    } else {
                        ctx.fillStyle = Qt.rgba(
                            ThemeManager.surfaceColor.r,
                            ThemeManager.surfaceColor.g,
                            ThemeManager.surfaceColor.b, 1)
                    }
                    ctx.fill()
                    ctx.shadowBlur = 0
                    ctx.strokeStyle = ThemeManager.primaryColor
                    ctx.lineWidth = isPinned ? 2 : 1
                    ctx.stroke()

                    // Label
                    var lbl = node.label || nid
                    if (lbl.length > 8) lbl = lbl.slice(0, 7) + "…"
                    ctx.fillStyle = ThemeManager.textColor
                    ctx.font = "bold 9px sans-serif"
                    ctx.textAlign = "center"
                    ctx.fillText(lbl, nx, ny + 3)
                }
            }

            function nodeAtPos(mx, my) {
                var ids = Object.keys(nodes)
                for (var i = ids.length - 1; i >= 0; i--) {
                    var nd = nodes[ids[i]]
                    var dx = mx - nd.x, dy = my - nd.y
                    if (dx*dx + dy*dy <= 400) return ids[i]
                }
                return null
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                property real pressX: 0
                property real pressY: 0
                property bool isDrag: false
                property string dragNodeId: ""
                property real lastClickTime: 0

                onPressed: (mouse) => {
                    pressX = mouse.x; pressY = mouse.y; isDrag = false
                    var nid = canvas.nodeAtPos(mouse.x, mouse.y)
                    if (nid) {
                        dragNodeId = nid
                        canvas.dragId = nid
                        canvas.dragOffX = mouse.x - nodes[nid].x
                        canvas.dragOffY = mouse.y - nodes[nid].y
                    } else {
                        dragNodeId = ""
                        canvas.dragId = null
                    }
                }

                onPositionChanged: (mouse) => {
                    if (canvas.dragId) {
                        var dx2 = mouse.x - pressX, dy2 = mouse.y - pressY
                        if (!isDrag && (dx2*dx2 + dy2*dy2 > 16)) isDrag = true
                        if (isDrag) {
                            var newX = mouse.x - canvas.dragOffX
                            var newY = mouse.y - canvas.dragOffY
                            var updated = JSON.parse(JSON.stringify(nodes))
                            updated[canvas.dragId].x = newX
                            updated[canvas.dragId].y = newY
                            nodes = updated
                            if (behaviourObject)
                                behaviourObject.setNodePos(canvas.dragId, newX, newY)
                            canvas.requestPaint()
                        }
                    }
                }

                onReleased: (mouse) => {
                    if (!isDrag && dragNodeId !== "") {
                        var now = Date.now()
                        if (now - lastClickTime < 400) {
                            // Double-click: toggle pin
                            if (behaviourObject)
                                behaviourObject.setPinned(dragNodeId, !nodes[dragNodeId].pinned)
                        } else {
                            // Single click: emit nodeClicked
                            if (behaviourObject)
                                behaviourObject.nodeClicked(dragNodeId, nodes[dragNodeId].label || dragNodeId)
                        }
                        lastClickTime = now
                    }
                    canvas.dragId = null
                    isDrag = false
                    dragNodeId = ""
                }
            }
        }

        // Status bar
        Rectangle {
            Layout.fillWidth: true
            height: 20
            color: ThemeManager.surfaceColor

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: "Drag nodes • Dbl-click to pin • Layout: " + selectedLayout
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 8
            }
        }
    }
}
