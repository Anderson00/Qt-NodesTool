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

    // ── Map state ─────────────────────────────────────────────────────────────
    property double centerLat: behaviourObject ? behaviourObject.centerLat : 48.8566
    property double centerLng: behaviourObject ? behaviourObject.centerLng : 2.3522
    property int    zoom:      behaviourObject ? behaviourObject.zoom      : 4
    property var    markers:   []
    property var    trace:     []

    // ── UI state ──────────────────────────────────────────────────────────────
    property bool   addMarkerMode:    false
    property string mapStyle:         "osm"   // osm | carto-light | carto-dark | topo
    property int    hoveredMarkerIdx: -1
    property double hoverLat:         0
    property double hoverLng:         0

    // ── Drag state ────────────────────────────────────────────────────────────
    property real dragStartX:   0
    property real dragStartY:   0
    property real dragStartLat: 0
    property real dragStartLng: 0
    property bool isDragging:   false

    // ── Scale bar (auto-updates on zoom / lat change) ─────────────────────────
    property var scaleInfo: {
        var metersPerPx = (Math.cos(centerLat * Math.PI / 180) * 2 * Math.PI * 6378137)
                          / (Math.pow(2, zoom) * 256)
        var target = metersPerPx * 80
        var steps  = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 50000, 100000]
        var best = steps[0]
        for (var i = 0; i < steps.length; i++) { best = steps[i]; if (steps[i] >= target) break }
        return { px: Math.round(best / metersPerPx), label: best >= 1000 ? (best / 1000) + " km" : best + " m" }
    }

    // ── Tile URL factory ──────────────────────────────────────────────────────
    function tileUrl(z, x, y) {
        switch (mapStyle) {
        case "carto-light": return "https://basemaps.cartocdn.com/rastertiles/voyager/" + z + "/" + x + "/" + y + ".png"
        case "carto-dark":  return "https://basemaps.cartocdn.com/dark_all/"            + z + "/" + x + "/" + y + ".png"
        case "topo":        return "https://tile.opentopomap.org/"                      + z + "/" + x + "/" + y + ".png"
        default:            return "https://tile.openstreetmap.org/"                    + z + "/" + x + "/" + y + ".png"
        }
    }

    // ── Projection helpers ────────────────────────────────────────────────────
    function lon2tile(lng, z) {
        return Math.floor((lng + 180) / 360 * Math.pow(2, z))
    }
    function lat2tile(lat, z) {
        return Math.floor((1 - Math.log(Math.tan(lat * Math.PI / 180) + 1 / Math.cos(lat * Math.PI / 180)) / Math.PI) / 2 * Math.pow(2, z))
    }

    // ── World-space pixel of a lat/lng relative to map centre ─────────────────
    //    BUG FIX: uses mapClip.width/height as reference (consistent with
    //    pixelToLatLng and the tile origin calculations in fullRefresh)
    function latLngToPixel(lat, lng) {
        var ts    = 256
        var scale = Math.pow(2, zoom) * ts
        var px    = (lng + 180) / 360 * scale
        var pxC   = (centerLng + 180) / 360 * scale
        var py    = (1 - Math.log(Math.tan(Math.PI / 4 + lat       * Math.PI / 360)) / Math.PI) / 2 * scale
        var pyC   = (1 - Math.log(Math.tan(Math.PI / 4 + centerLat * Math.PI / 360)) / Math.PI) / 2 * scale
        return Qt.point(mapClip.width  / 2 + (px - pxC),
                        mapClip.height / 2 + (py - pyC))
    }

    function pixelToLatLng(screenX, screenY) {
        var ts    = 256
        var scale = Math.pow(2, zoom) * ts
        var dx    = screenX - mapClip.width  / 2
        var dy    = screenY - mapClip.height / 2
        var lng   = centerLng + dx / scale * 360
        var cPy   = (1 - Math.log(Math.tan(Math.PI / 4 + centerLat * Math.PI / 360)) / Math.PI) / 2
        var nPy   = Math.max(0.001, Math.min(0.999, cPy + dy / scale))
        var lat   = 180 / Math.PI * (2 * Math.atan(Math.exp((1 - 2 * nPy) * Math.PI)) - Math.PI / 2)
        return Qt.point(lat, lng)   // .x = lat, .y = lng
    }

    // ── Find nearest visible marker (returns -1 if none within threshold px) ──
    function findNearestMarkerIdx(mx, my, threshold) {
        var best     = -1
        var bestDist = threshold * threshold
        for (var i = 0; i < root.markers.length; i++) {
            var mp   = root.latLngToPixel(root.markers[i].lat, root.markers[i].lng)
            // test against circle centre (pin is drawn at mp.y - 11)
            var dist = (mx - mp.x) * (mx - mp.x) + (my - (mp.y - 11)) * (my - (mp.y - 11))
            if (dist < bestDist) { bestDist = dist; best = i }
        }
        return best
    }

    // ── C++ signal bridge ─────────────────────────────────────────────────────
    Connections {
        target: behaviourObject
        function onInternalMarkersChanged() {
            if (behaviourObject) root.markers = behaviourObject.getMarkers()
            root.hoveredMarkerIdx = -1
            overlayCanvas.requestPaint()
        }
        function onInternalTraceChanged() {
            if (behaviourObject) root.trace = behaviourObject.getTrace()
            overlayCanvas.requestPaint()
        }
        function onInternalCenterChanged(lat, lng, z) {
            root.centerLat = lat; root.centerLng = lng; root.zoom = z
            tileLayer.fullRefresh(); overlayCanvas.requestPaint()
        }
        function onInternalClear() {
            root.markers = []; root.trace = []
            root.hoveredMarkerIdx = -1
            tileLayer.fullRefresh(); overlayCanvas.requestPaint()
        }
    }

    Component.onCompleted: tileLayer.fullRefresh()

    // ── Root layout ───────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: ThemeManager.surfaceColor
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: ThemeManager.borderColor }

            RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                spacing: 4

                Text { text: "Map"; color: ThemeManager.textColor; font.pixelSize: 11; font.bold: true }
                Rectangle { width: 1; height: 20; color: ThemeManager.borderColor; opacity: 0.5 }

                // Map-style selector
                Repeater {
                    model: [
                        { id: "osm",         label: "Streets" },
                        { id: "carto-light", label: "Light"   },
                        { id: "carto-dark",  label: "Dark"    },
                        { id: "topo",        label: "Topo"    }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        property bool active: root.mapStyle === modelData.id
                        width: styleLabel.width + 14; height: 22; radius: 4
                        color: active ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15) : "transparent"
                        border.color: active ? ThemeManager.primaryColor : "transparent"; border.width: 1
                        Text {
                            id: styleLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: active ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                            font.pixelSize: 10
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { root.mapStyle = modelData.id; tileLayer.fullRefresh() }
                        }
                    }
                }

                Rectangle { width: 1; height: 20; color: ThemeManager.borderColor; opacity: 0.5 }

                // Add-marker toggle
                Rectangle {
                    width: markerBtnLabel.width + 22; height: 22; radius: 4
                    color: root.addMarkerMode ? Qt.rgba(0.13, 0.79, 0.26, 0.18) : "transparent"
                    border.color: root.addMarkerMode ? "#22c55e" : ThemeManager.borderColor; border.width: 1
                    Text {
                        id: markerBtnLabel
                        anchors.centerIn: parent
                        text: root.addMarkerMode ? "✕ Cancelar" : "+ Marker"
                        color: root.addMarkerMode ? "#22c55e" : ThemeManager.textSecondaryColor
                        font.pixelSize: 10
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.addMarkerMode = !root.addMarkerMode }
                }

                Item { Layout.fillWidth: true }

                // Zoom controls
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: zmHov.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.12) : "transparent"
                    border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "−"; color: ThemeManager.textColor; font.pixelSize: 16; font.bold: true }
                    MouseArea {
                        id: zmHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (root.zoom > 1) { root.zoom--; tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                    }
                }
                Text { text: root.zoom; color: ThemeManager.textColor; font.pixelSize: 11; width: 20; horizontalAlignment: Text.AlignHCenter }
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: zpHov.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.12) : "transparent"
                    border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "+"; color: ThemeManager.textColor; font.pixelSize: 16; font.bold: true }
                    MouseArea {
                        id: zpHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (root.zoom < 19) { root.zoom++; tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                    }
                }

                Rectangle { width: 1; height: 20; color: ThemeManager.borderColor; opacity: 0.5 }

                Rectangle {
                    width: 40; height: 22; radius: 4
                    color: clrHov.containsMouse ? Qt.rgba(0.5, 0.5, 0.5, 0.12) : "transparent"
                    border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "Clear"; color: ThemeManager.textSecondaryColor; font.pixelSize: 10 }
                    MouseArea {
                        id: clrHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (behaviourObject) behaviourObject.clearAll()
                    }
                }
            }
        }

        // ── Map area ──────────────────────────────────────────────────────────
        Rectangle {
            id: mapClip
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.mapStyle === "carto-dark" ? "#1a1a2e" : "#c8dff0"
            clip: true
            focus: true

            // Keyboard navigation (arrow keys + WASD + +/-)
            Keys.onPressed: function(event) {
                var step  = 40
                var ts    = 256
                var scale = Math.pow(2, root.zoom) * ts

                function shiftLat(dy) {
                    var cpy = (1 - Math.log(Math.tan(Math.PI/4 + root.centerLat*Math.PI/360))/Math.PI)/2
                    var npy = Math.max(0.001, Math.min(0.999, cpy + dy / scale))
                    root.centerLat = 180/Math.PI*(2*Math.atan(Math.exp((1-2*npy)*Math.PI))-Math.PI/2)
                }

                if (event.key === Qt.Key_Left  || event.key === Qt.Key_A) { root.centerLng -= step / scale * 360;  tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                if (event.key === Qt.Key_Right || event.key === Qt.Key_D) { root.centerLng += step / scale * 360;  tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                if (event.key === Qt.Key_Up    || event.key === Qt.Key_W) { shiftLat(-step); tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                if (event.key === Qt.Key_Down  || event.key === Qt.Key_S) { shiftLat( step); tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                if (event.key === Qt.Key_Plus  || event.key === Qt.Key_Equal) {
                    if (root.zoom < 19) { root.zoom++; tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                }
                if (event.key === Qt.Key_Minus) {
                    if (root.zoom > 1)  { root.zoom--; tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                }
            }

            // ── Tile layer (double-buffered) ──────────────────────────────────
            //
            //  FIX: prevLayer / currLayer no longer use anchors.fill because
            //  setting .x/.y on anchored items causes anchor conflicts in QML
            //  (the anchor binding may override the explicit value, making the
            //  tile layer not translate — which desynchronises markers).
            //  Instead we keep width/height bound to parent and use a
            //  transform: Translate so positional panning is clean.
            //
            Item {
                id: tileLayer
                anchors.fill: parent

                Item {
                    id: prevLayer
                    width: parent.width; height: parent.height
                    transform: Translate { id: prevTranslate }
                }
                Item {
                    id: currLayer
                    width: parent.width; height: parent.height
                    transform: Translate { id: currTranslate }
                }

                property var prevTiles: []
                property var currTiles: []

                Timer {
                    id: prevCleanup
                    interval: 900
                    onTriggered: {
                        for (var i = 0; i < tileLayer.prevTiles.length; i++) tileLayer.prevTiles[i].destroy()
                        tileLayer.prevTiles = []
                    }
                }

                // Pan: translate both layers immediately — no tile re-load during drag
                function panBy(dx, dy) {
                    currTranslate.x = dx; currTranslate.y = dy
                    prevTranslate.x = dx; prevTranslate.y = dy
                }

                // Full tile reload at current centerLat/Lng/zoom
                function fullRefresh() {
                    // Reset any live pan translation first
                    currTranslate.x = 0; currTranslate.y = 0
                    prevTranslate.x = 0; prevTranslate.y = 0

                    // Swap buffers: current → previous (stays visible while new loads)
                    prevCleanup.stop()
                    for (var k = 0; k < prevTiles.length; k++) prevTiles[k].destroy()
                    prevTiles = currTiles
                    for (var j = 0; j < prevTiles.length; j++) prevTiles[j].parent = prevLayer
                    currTiles = []
                    prevCleanup.restart()

                    var ts      = 256
                    var maxTile = Math.pow(2, root.zoom)
                    var cTX     = root.lon2tile(root.centerLng, root.zoom)
                    var cTY     = root.lat2tile(root.centerLat, root.zoom)
                    var tilesW  = Math.ceil(currLayer.width  / ts) + 3
                    var tilesH  = Math.ceil(currLayer.height / ts) + 3

                    // Sub-tile offset of the centre coordinate within tile (cTX, cTY)
                    var totalPxX = (root.centerLng + 180) / 360 * maxTile * ts
                    var subX     = totalPxX - cTX * ts
                    var cPy      = (1 - Math.log(Math.tan(Math.PI / 4 + root.centerLat * Math.PI / 360)) / Math.PI) / 2
                    var subY     = cPy * maxTile * ts - cTY * ts

                    // Screen pixel where tile (cTX, cTY) origin should be placed
                    var originX = currLayer.width  / 2 - subX
                    var originY = currLayer.height / 2 - subY

                    for (var dx = -Math.floor(tilesW / 2) - 1; dx <= Math.ceil(tilesW / 2) + 1; dx++) {
                        for (var dy = -Math.floor(tilesH / 2) - 1; dy <= Math.ceil(tilesH / 2) + 1; dy++) {
                            var tx = ((cTX + dx) % maxTile + maxTile) % maxTile
                            var ty = cTY + dy
                            if (ty < 0 || ty >= maxTile) continue
                            var obj = tileComp.createObject(currLayer, {
                                x:      originX + dx * ts,
                                y:      originY + dy * ts,
                                source: root.tileUrl(root.zoom, tx, ty)
                            })
                            if (obj) currTiles.push(obj)
                        }
                    }
                }

                Component {
                    id: tileComp
                    Image {
                        width: 256; height: 256
                        fillMode: Image.Stretch
                        cache: true; smooth: true; asynchronous: true
                        opacity: 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        onStatusChanged: if (status === Image.Ready) opacity = 1
                    }
                }
            }

            // ── Overlay canvas (markers + trace) ──────────────────────────────
            Canvas {
                id: overlayCanvas
                anchors.fill: parent

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    // ── GPS trace ──────────────────────────────────────────────
                    var tr = root.trace
                    if (tr.length > 1) {
                        ctx.beginPath()
                        ctx.strokeStyle = "#3b82f6"
                        ctx.lineWidth   = 3
                        ctx.lineJoin    = "round"
                        ctx.lineCap     = "round"
                        var p0 = root.latLngToPixel(tr[0].lat, tr[0].lng)
                        ctx.moveTo(p0.x, p0.y)
                        for (var i = 1; i < tr.length; i++) {
                            var pi = root.latLngToPixel(tr[i].lat, tr[i].lng)
                            ctx.lineTo(pi.x, pi.y)
                        }
                        ctx.stroke()

                        // Start / end dots on the trace
                        var pFirst = root.latLngToPixel(tr[0].lat, tr[0].lng)
                        ctx.beginPath(); ctx.arc(pFirst.x, pFirst.y, 5, 0, 2 * Math.PI)
                        ctx.fillStyle = "#22c55e"; ctx.fill()
                        var pLast = root.latLngToPixel(tr[tr.length - 1].lat, tr[tr.length - 1].lng)
                        ctx.beginPath(); ctx.arc(pLast.x, pLast.y, 5, 0, 2 * Math.PI)
                        ctx.fillStyle = "#ef4444"; ctx.fill()
                    }

                    // ── Markers ────────────────────────────────────────────────
                    for (var j = 0; j < root.markers.length; j++) {
                        var m        = root.markers[j]
                        var mp       = root.latLngToPixel(m.lat, m.lng)
                        var mc       = m.type === "start" ? "#22c55e"
                                     : m.type === "end"   ? "#ef4444"
                                     :                      "#6366f1"
                        var hovered  = (j === root.hoveredMarkerIdx)
                        var radius   = hovered ? 10 : 8

                        // Hover glow ring
                        if (hovered) {
                            ctx.beginPath()
                            ctx.arc(mp.x, mp.y - 11, 16, 0, 2 * Math.PI)
                            ctx.fillStyle = Qt.rgba(0.38, 0.4, 0.95, 0.18)
                            ctx.fill()
                        }

                        // Drop shadow
                        ctx.shadowColor = "rgba(0,0,0,0.35)"
                        ctx.shadowBlur  = 5

                        // Pin circle
                        ctx.beginPath()
                        ctx.arc(mp.x, mp.y - 11, radius, 0, 2 * Math.PI)
                        ctx.fillStyle   = mc
                        ctx.fill()
                        ctx.strokeStyle = "white"
                        ctx.lineWidth   = 1.5
                        ctx.stroke()

                        ctx.shadowBlur = 0   // reset shadow for remaining draws

                        // Inner dot
                        ctx.beginPath()
                        ctx.arc(mp.x, mp.y - 11, 3, 0, 2 * Math.PI)
                        ctx.fillStyle = "white"
                        ctx.fill()

                        // Number badge (regular markers only)
                        if (m.type === "marker") {
                            ctx.font      = "bold 8px sans-serif"
                            ctx.fillStyle = "white"
                            ctx.textAlign = "center"
                            ctx.fillText(j + 1, mp.x, mp.y - 7)
                            ctx.textAlign = "left"
                        }

                        // Pin tail triangle
                        var tailW = hovered ? 6 : 5
                        ctx.beginPath()
                        ctx.moveTo(mp.x - tailW, mp.y - 5)
                        ctx.lineTo(mp.x,         mp.y)
                        ctx.lineTo(mp.x + tailW, mp.y - 5)
                        ctx.closePath()
                        ctx.fillStyle = mc
                        ctx.fill()

                        // Label bubble
                        if (m.label) {
                            ctx.font = "bold 10px sans-serif"
                            var lx  = mp.x + 14
                            var ly  = mp.y - 14
                            var tw  = ctx.measureText(m.label).width
                            var bgC = root.mapStyle === "carto-dark" ? "rgba(20,20,20,0.75)"
                                                                     : "rgba(255,255,255,0.88)"
                            ctx.fillStyle = bgC
                            ctx.beginPath()
                            if (ctx.roundRect) ctx.roundRect(lx - 3, ly - 11, tw + 8, 16, 3)
                            else               ctx.rect(lx - 3, ly - 11, tw + 8, 16)
                            ctx.fill()
                            ctx.fillStyle = root.mapStyle === "carto-dark" ? "#e8e8e8" : "#111"
                            ctx.fillText(m.label, lx, ly)
                        }
                    }

                    // ── Hover "RMB: remover" hint ──────────────────────────────
                    if (root.hoveredMarkerIdx >= 0 && !root.isDragging && !root.addMarkerMode) {
                        var hm = root.markers[root.hoveredMarkerIdx]
                        if (hm && hm.type === "marker") {
                            var hmp  = root.latLngToPixel(hm.lat, hm.lng)
                            var hint = "⌦ botão direito: remover"
                            ctx.font  = "9px sans-serif"
                            var htw  = ctx.measureText(hint).width
                            var hbgC = root.mapStyle === "carto-dark" ? "rgba(20,20,20,0.82)" : "rgba(255,255,255,0.90)"
                            ctx.fillStyle = hbgC
                            ctx.beginPath()
                            if (ctx.roundRect) ctx.roundRect(hmp.x - htw / 2 - 5, hmp.y - 37, htw + 10, 15, 3)
                            else               ctx.rect(hmp.x - htw / 2 - 5, hmp.y - 37, htw + 10, 15)
                            ctx.fill()
                            ctx.fillStyle = root.mapStyle === "carto-dark" ? "#aaa" : "#555"
                            ctx.textAlign = "center"
                            ctx.fillText(hint, hmp.x, hmp.y - 26)
                            ctx.textAlign = "left"
                        }
                    }

                    // ── Add-marker ghost cursor + coordinate tooltip ────────────
                    if (root.addMarkerMode && mapArea.containsMouse) {
                        var mx = mapArea.mouseX
                        var my = mapArea.mouseY

                        // Ghost pin
                        ctx.beginPath()
                        ctx.arc(mx, my - 11, 8, 0, 2 * Math.PI)
                        ctx.fillStyle   = Qt.rgba(0.13, 0.79, 0.26, 0.45)
                        ctx.fill()
                        ctx.strokeStyle = "#22c55e"
                        ctx.lineWidth   = 2
                        ctx.stroke()
                        ctx.beginPath()
                        ctx.moveTo(mx - 5, my - 5); ctx.lineTo(mx, my); ctx.lineTo(mx + 5, my - 5)
                        ctx.closePath()
                        ctx.fillStyle = Qt.rgba(0.13, 0.79, 0.26, 0.45)
                        ctx.fill()

                        // Coordinate tooltip below cursor
                        var coord  = root.pixelToLatLng(mx, my)
                        var tip    = coord.x.toFixed(5) + ",  " + coord.y.toFixed(5)
                        ctx.font   = "10px Consolas, monospace"
                        var tipW   = ctx.measureText(tip).width
                        var tipX   = Math.min(mx + 14, width  - tipW - 12)
                        var tipY   = Math.min(my + 8,  height - 24)
                        var tipBgC = root.mapStyle === "carto-dark" ? "rgba(10,10,10,0.80)" : "rgba(255,255,255,0.92)"
                        ctx.fillStyle = tipBgC
                        ctx.beginPath()
                        if (ctx.roundRect) ctx.roundRect(tipX - 4, tipY, tipW + 8, 18, 4)
                        else               ctx.rect(tipX - 4, tipY, tipW + 8, 18)
                        ctx.fill()
                        ctx.fillStyle = root.mapStyle === "carto-dark" ? "#ddd" : "#222"
                        ctx.fillText(tip, tipX, tipY + 13)
                    }
                }
            }

            // ── Scale bar ──────────────────────────────────────────────────────
            Item {
                anchors { left: parent.left; bottom: parent.bottom; leftMargin: 10; bottomMargin: 6 }

                Text {
                    id: scaleLabel
                    anchors { horizontalCenter: scaleBarRect.horizontalCenter; bottom: scaleBarRect.top; bottomMargin: 2 }
                    text: root.scaleInfo ? root.scaleInfo.label : ""
                    color: root.mapStyle === "carto-dark" ? "white" : "#222"
                    font.pixelSize: 9
                    style: Text.Outline
                    styleColor: root.mapStyle === "carto-dark" ? "#111" : "white"
                }

                Rectangle {
                    id: scaleBarRect
                    anchors { bottom: parent.bottom; left: parent.left; bottomMargin: 12 }
                    width:  root.scaleInfo ? Math.max(20, Math.min(root.scaleInfo.px, 120)) : 60
                    height: 3
                    color: root.mapStyle === "carto-dark" ? "white" : "#333"

                    Rectangle { width: 1; height: 7; color: parent.color; anchors { left: parent.left;  verticalCenter: parent.verticalCenter } }
                    Rectangle { width: 1; height: 7; color: parent.color; anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
                }
            }

            // ── OSM attribution (legally required) ────────────────────────────
            Text {
                anchors { right: parent.right; bottom: parent.bottom; rightMargin: 5; bottomMargin: 3 }
                text: root.mapStyle === "topo" ? "© OpenTopoMap | © OpenStreetMap"
                                               : "© OpenStreetMap contributors"
                color: root.mapStyle === "carto-dark" ? "rgba(200,200,200,0.55)" : "rgba(60,60,60,0.65)"
                font.pixelSize: 8
            }

            // ── Add-marker mode banner ─────────────────────────────────────────
            Rectangle {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
                visible: root.addMarkerMode
                width: bannerText.width + 24; height: 26; radius: 13
                color: "#22c55e"
                Text {
                    id: bannerText
                    anchors.centerIn: parent
                    text: "Clique no mapa para posicionar o marcador"
                    color: "white"; font.pixelSize: 11; font.bold: true
                }
            }

            // ── Mouse area ────────────────────────────────────────────────────
            MouseArea {
                id: mapArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                // Cursor reflects interaction state
                cursorShape: root.addMarkerMode        ? Qt.CrossCursor :
                             root.isDragging           ? Qt.ClosedHandCursor :
                             root.hoveredMarkerIdx >= 0 ? Qt.PointingHandCursor :
                                                          Qt.OpenHandCursor

                onPressed: function(mouse) {
                    mapClip.forceActiveFocus()
                    if (mouse.button !== Qt.LeftButton) return
                    root.dragStartX   = mouse.x
                    root.dragStartY   = mouse.y
                    root.dragStartLat = root.centerLat
                    root.dragStartLng = root.centerLng
                    root.isDragging   = false
                    markerPopup.visible = false
                }

                onPositionChanged: function(mouse) {
                    // Always track hover coord (shown in status bar)
                    var c = root.pixelToLatLng(mouse.x, mouse.y)
                    root.hoverLat = c.x; root.hoverLng = c.y

                    if (root.addMarkerMode) {
                        overlayCanvas.requestPaint()
                        return
                    }

                    // Marker hover detection
                    var prev = root.hoveredMarkerIdx
                    root.hoveredMarkerIdx = root.findNearestMarkerIdx(mouse.x, mouse.y, 14)
                    if (root.hoveredMarkerIdx !== prev) overlayCanvas.requestPaint()

                    if (!pressed || mouse.buttons !== Qt.LeftButton) return

                    var dx = mouse.x - root.dragStartX
                    var dy = mouse.y - root.dragStartY
                    if (!root.isDragging && (Math.abs(dx) > 3 || Math.abs(dy) > 3))
                        root.isDragging = true

                    if (root.isDragging) {
                        tileLayer.panBy(dx, dy)

                        // Update logical centre so overlay redraws markers in the right place
                        var ts    = 256
                        var scale = Math.pow(2, root.zoom) * ts
                        root.centerLng = root.dragStartLng - dx / scale * 360
                        var cPy = (1 - Math.log(Math.tan(Math.PI / 4 + root.dragStartLat * Math.PI / 360)) / Math.PI) / 2
                        var nPy = Math.max(0.001, Math.min(0.999, cPy - dy / scale))
                        root.centerLat = 180 / Math.PI * (2 * Math.atan(Math.exp((1 - 2 * nPy) * Math.PI)) - Math.PI / 2)
                        overlayCanvas.requestPaint()
                    }
                }

                onReleased: function(mouse) {
                    if (mouse.button !== Qt.LeftButton) return
                    if (root.isDragging) {
                        // Pan finished — reload tiles at new centre
                        tileLayer.fullRefresh()
                        overlayCanvas.requestPaint()
                    } else {
                        // Simple click
                        var coord = root.pixelToLatLng(mouse.x, mouse.y)
                        if (root.addMarkerMode) {
                            markerPopup.pendingLat = coord.x
                            markerPopup.pendingLng = coord.y
                            markerPopup.labelField.text = ""
                            var px = Math.min(mouse.x + 8, mapClip.width  - markerPopup.width  - 8)
                            var py = Math.min(mouse.y + 8, mapClip.height - markerPopup.height - 8)
                            markerPopup.x = px; markerPopup.y = py
                            markerPopup.visible = true
                            markerPopup.labelField.forceActiveFocus()
                        } else if (behaviourObject) {
                            behaviourObject.mapClicked(coord.x, coord.y)
                        }
                    }
                    root.isDragging = false
                }

                // Right-click on a regular marker → remove it
                onClicked: function(mouse) {
                    if (mouse.button !== Qt.RightButton) return
                    var idx = root.findNearestMarkerIdx(mouse.x, mouse.y, 16)
                    if (idx >= 0 && behaviourObject) {
                        var m = root.markers[idx]
                        if (m && m.type === "marker") behaviourObject.removeMarkerAt(idx)
                    }
                }

                // Zoom toward the cursor position (standard map behaviour)
                onWheel: function(wheel) {
                    var delta   = wheel.angleDelta.y > 0 ? 1 : -1
                    var newZoom = Math.max(1, Math.min(19, root.zoom + delta))
                    if (newZoom === root.zoom) return

                    var ts       = 256
                    var newScale = Math.pow(2, newZoom) * ts

                    // Lat/lng currently under the cursor
                    var cursorCoord = root.pixelToLatLng(wheel.x, wheel.y)

                    // New centre: keep cursor coord fixed at (wheel.x, wheel.y)
                    root.centerLng = cursorCoord.y - (wheel.x - mapClip.width  / 2) / newScale * 360

                    var cursorPy    = (1 - Math.log(Math.tan(Math.PI / 4 + cursorCoord.x * Math.PI / 360)) / Math.PI) / 2
                    var newCenterPy = Math.max(0.001, Math.min(0.999,
                                         cursorPy - (wheel.y - mapClip.height / 2) / newScale))
                    root.centerLat  = 180 / Math.PI * (2 * Math.atan(Math.exp((1 - 2 * newCenterPy) * Math.PI)) - Math.PI / 2)

                    root.zoom = newZoom
                    tileLayer.fullRefresh()
                    overlayCanvas.requestPaint()
                }

                onExited: {
                    root.hoveredMarkerIdx = -1
                    overlayCanvas.requestPaint()
                }
            }

            // ── Marker label popup ────────────────────────────────────────────
            Rectangle {
                id: markerPopup
                visible: false
                z: 200
                width: 210; height: 72; radius: 8
                color: ThemeManager.surfaceColor
                border.color: "#22c55e"; border.width: 1.5

                property real  pendingLat: 0
                property real  pendingLng: 0
                property alias labelField: lblInput

                Column {
                    anchors { fill: parent; margins: 10 }
                    spacing: 6

                    Text { text: "Label do marcador (opcional)"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }

                    Row {
                        spacing: 6; width: parent.width
                        Rectangle {
                            width: parent.width - 58; height: 24; radius: 4
                            color: ThemeManager.backgroundColor
                            border.color: ThemeManager.borderColor
                            TextInput {
                                id: lblInput
                                anchors { fill: parent; leftMargin: 7; rightMargin: 7; topMargin: 4; bottomMargin: 4 }
                                color: ThemeManager.textColor; font.pixelSize: 11
                                Keys.onReturnPressed: markerPopup.confirm()
                                Keys.onEscapePressed: markerPopup.visible = false
                            }
                        }
                        Rectangle {
                            width: 52; height: 24; radius: 4; color: "#22c55e"
                            Text { anchors.centerIn: parent; text: "Adicionar"; color: "white"; font.pixelSize: 9; font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: markerPopup.confirm() }
                        }
                    }
                }

                function confirm() {
                    if (behaviourObject)
                        behaviourObject.addMarker(pendingLat, pendingLng, lblInput.text || "")
                    visible = false
                    root.addMarkerMode = false
                }
            }
        }

        // ── Status bar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 22
            color: ThemeManager.surfaceColor
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: ThemeManager.borderColor }

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 12

                Text {
                    text: (behaviourObject ? behaviourObject.markerCount : 0) + " marcadores"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                }
                Text {
                    text: (behaviourObject ? behaviourObject.traceLength : 0) + " pts rastreio"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                }
                Item { Layout.fillWidth: true }
                // Live cursor coordinates
                Text {
                    text: root.hoverLat.toFixed(5) + ",  " + root.hoverLng.toFixed(5)
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                    font.family: "Consolas, monospace"
                }
            }
        }
    }
}
