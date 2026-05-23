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
    property bool   addMarkerMode: false
    property string mapStyle:      "osm"   // osm | carto-light | carto-dark | topo

    // ── Drag state ────────────────────────────────────────────────────────────
    property real   dragStartX:   0
    property real   dragStartY:   0
    property real   dragStartLat: 0
    property real   dragStartLng: 0
    property bool   isDragging:   false

    // ── Tile URL factory ──────────────────────────────────────────────────────
    function tileUrl(z, x, y) {
        switch (mapStyle) {
        case "carto-light": return "https://basemaps.cartocdn.com/rastertiles/voyager/"  + z + "/" + x + "/" + y + ".png"
        case "carto-dark":  return "https://basemaps.cartocdn.com/dark_all/"             + z + "/" + x + "/" + y + ".png"
        case "topo":        return "https://tile.opentopomap.org/"                       + z + "/" + x + "/" + y + ".png"
        default:            return "https://tile.openstreetmap.org/"                     + z + "/" + x + "/" + y + ".png"
        }
    }

    // ── Tile / projection math ─────────────────────────────────────────────────
    function lon2tile(lng, z) { return Math.floor((lng + 180) / 360 * Math.pow(2, z)) }
    function lat2tile(lat, z) {
        return Math.floor((1 - Math.log(Math.tan(lat * Math.PI/180) + 1/Math.cos(lat * Math.PI/180)) / Math.PI) / 2 * Math.pow(2, z))
    }
    function latLngToPixel(lat, lng) {
        var ts    = 256
        var scale = Math.pow(2, zoom) * ts
        var px    = (lng + 180) / 360 * scale
        var pxC   = (centerLng + 180) / 360 * scale
        var py    = (1 - Math.log(Math.tan(Math.PI/4 + lat       * Math.PI/360)) / Math.PI) / 2 * scale
        var pyC   = (1 - Math.log(Math.tan(Math.PI/4 + centerLat * Math.PI/360)) / Math.PI) / 2 * scale
        return Qt.point(overlayCanvas.width/2  + (px - pxC),
                        overlayCanvas.height/2 + (py - pyC))
    }
    function pixelToLatLng(screenX, screenY) {
        var ts    = 256
        var scale = Math.pow(2, zoom) * ts
        var dx    = screenX - mapClip.width/2
        var dy    = screenY - mapClip.height/2
        var lng   = centerLng + dx / scale * 360
        var cPy   = (1 - Math.log(Math.tan(Math.PI/4 + centerLat * Math.PI/360)) / Math.PI) / 2
        var nPy   = Math.max(0.001, Math.min(0.999, cPy + dy / scale))
        var lat   = 180/Math.PI * (2*Math.atan(Math.exp((1 - 2*nPy) * Math.PI)) - Math.PI/2)
        return Qt.point(lat, lng)   // .x = lat, .y = lng
    }

    // ── C++ signals ───────────────────────────────────────────────────────────
    Connections {
        target: behaviourObject
        function onInternalMarkersChanged()         { if (behaviourObject) root.markers = behaviourObject.getMarkers(); overlayCanvas.requestPaint() }
        function onInternalTraceChanged()           { if (behaviourObject) root.trace   = behaviourObject.getTrace();   overlayCanvas.requestPaint() }
        function onInternalCenterChanged(lat,lng,z) { root.centerLat=lat; root.centerLng=lng; root.zoom=z; tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
        function onInternalClear()                  { root.markers=[]; root.trace=[]; tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
    }

    Component.onCompleted: tileLayer.fullRefresh()

    // ── Layout ────────────────────────────────────────────────────────────────
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

                // Map style selector
                Repeater {
                    model: [
                        { id: "osm",         label: "Streets"  },
                        { id: "carto-light", label: "Light"    },
                        { id: "carto-dark",  label: "Dark"     },
                        { id: "topo",        label: "Topo"     }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        property bool active: root.mapStyle === modelData.id
                        width: styleLabel.width + 14; height: 22; radius: 4
                        color:  active ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15) : "transparent"
                        border.color: active ? ThemeManager.primaryColor : "transparent"
                        border.width: 1
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

                // Add Marker toggle
                Rectangle {
                    width: markerBtnLabel.width + 22; height: 22; radius: 4
                    color:  root.addMarkerMode ? Qt.rgba(0.13, 0.79, 0.26, 0.18) : "transparent"
                    border.color: root.addMarkerMode ? "#22c55e" : ThemeManager.borderColor
                    border.width: 1
                    Text {
                        id: markerBtnLabel
                        anchors.centerIn: parent
                        text: root.addMarkerMode ? "Cancel" : "+ Marker"
                        color: root.addMarkerMode ? "#22c55e" : ThemeManager.textSecondaryColor
                        font.pixelSize: 10
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.addMarkerMode = !root.addMarkerMode }
                }

                Item { Layout.fillWidth: true }

                // Zoom -
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: zmHov.containsMouse ? Qt.rgba(0.5,0.5,0.5,0.12) : "transparent"
                    border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "−"; color: ThemeManager.textColor; font.pixelSize: 16; font.bold: true }
                    MouseArea { id: zmHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (root.zoom > 1) { root.zoom--; tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                    }
                }
                Text { text: root.zoom; color: ThemeManager.textColor; font.pixelSize: 11; width: 20; horizontalAlignment: Text.AlignHCenter }
                // Zoom +
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: zpHov.containsMouse ? Qt.rgba(0.5,0.5,0.5,0.12) : "transparent"
                    border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "+"; color: ThemeManager.textColor; font.pixelSize: 16; font.bold: true }
                    MouseArea { id: zpHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (root.zoom < 19) { root.zoom++; tileLayer.fullRefresh(); overlayCanvas.requestPaint() }
                    }
                }

                Rectangle { width: 1; height: 20; color: ThemeManager.borderColor; opacity: 0.5 }

                Rectangle {
                    width: 40; height: 22; radius: 4
                    color: clrHov.containsMouse ? Qt.rgba(0.5,0.5,0.5,0.12) : "transparent"
                    border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "Clear"; color: ThemeManager.textSecondaryColor; font.pixelSize: 10 }
                    MouseArea { id: clrHov; anchors.fill: parent; hoverEnabled: true
                        onClicked: if (behaviourObject) behaviourObject.clearAll()
                    }
                }
            }
        }

        // ── Map clip area ─────────────────────────────────────────────────────
        Rectangle {
            id: mapClip
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.mapStyle === "carto-dark" ? "#1a1a2e" : "#c8dff0"
            clip: true

            // ── Tile layer (double-buffered) ───────────────────────────────────
            Item {
                id: tileLayer
                anchors.fill: parent

                // Previous tiles kept until new ones fade in (prevents blue flash)
                Item { id: prevLayer; anchors.fill: parent }
                // Current tiles loaded here
                Item { id: currLayer; anchors.fill: parent }

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

                // Pan: translate currLayer without touching prevLayer (instant, no network)
                function panBy(dx, dy) {
                    currLayer.x = dx
                    currLayer.y = dy
                    prevLayer.x = dx
                    prevLayer.y = dy
                }

                // Full reload at current centerLat/Lng/zoom
                function fullRefresh() {
                    // Reset any pan translation first
                    currLayer.x = 0; currLayer.y = 0
                    prevLayer.x = 0; prevLayer.y = 0

                    // Move current → prev (stay visible as background)
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

                    var totalPxX = (root.centerLng + 180) / 360 * maxTile * ts
                    var subX     = totalPxX - cTX * ts
                    var cPy      = (1 - Math.log(Math.tan(Math.PI/4 + root.centerLat * Math.PI/360)) / Math.PI) / 2
                    var subY     = cPy * maxTile * ts - cTY * ts
                    var originX  = currLayer.width/2  - subX
                    var originY  = currLayer.height/2 - subY

                    for (var dx = -Math.floor(tilesW/2) - 1; dx <= Math.ceil(tilesW/2) + 1; dx++) {
                        for (var dy = -Math.floor(tilesH/2) - 1; dy <= Math.ceil(tilesH/2) + 1; dy++) {
                            var tx = ((cTX + dx) % maxTile + maxTile) % maxTile
                            var ty = cTY + dy
                            if (ty < 0 || ty >= maxTile) continue
                            var obj = tileComp.createObject(currLayer, {
                                x: originX + dx * ts,
                                y: originY + dy * ts,
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

            // ── Marker + trace overlay ─────────────────────────────────────────
            Canvas {
                id: overlayCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    // Trace line
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
                    }

                    // Markers
                    for (var j = 0; j < root.markers.length; j++) {
                        var m   = root.markers[j]
                        var mp  = root.latLngToPixel(m.lat, m.lng)
                        var mc  = m.type === "start" ? "#22c55e" : m.type === "end" ? "#ef4444" : "#6366f1"

                        // Pin circle
                        ctx.beginPath()
                        ctx.arc(mp.x, mp.y - 11, 8, 0, 2*Math.PI)
                        ctx.fillStyle   = mc
                        ctx.fill()
                        ctx.strokeStyle = "white"
                        ctx.lineWidth   = 1.5
                        ctx.stroke()

                        // Inner dot
                        ctx.beginPath()
                        ctx.arc(mp.x, mp.y - 11, 3, 0, 2*Math.PI)
                        ctx.fillStyle = "white"
                        ctx.fill()

                        // Pin tail (triangle)
                        ctx.beginPath()
                        ctx.moveTo(mp.x - 5, mp.y - 5)
                        ctx.lineTo(mp.x,     mp.y)
                        ctx.lineTo(mp.x + 5, mp.y - 5)
                        ctx.closePath()
                        ctx.fillStyle = mc
                        ctx.fill()

                        // Label
                        if (m.label) {
                            ctx.font      = "bold 10px sans-serif"
                            ctx.fillStyle = root.mapStyle === "carto-dark" ? "white" : "#111"
                            ctx.fillText(m.label, mp.x + 12, mp.y - 8)
                        }
                    }

                    // Add-marker ghost cursor
                    if (root.addMarkerMode && mapArea.containsMouse) {
                        ctx.beginPath()
                        ctx.arc(mapArea.mouseX, mapArea.mouseY - 11, 8, 0, 2*Math.PI)
                        ctx.fillStyle   = Qt.rgba(0.13, 0.79, 0.26, 0.45)
                        ctx.fill()
                        ctx.strokeStyle = "#22c55e"
                        ctx.lineWidth   = 2
                        ctx.stroke()
                        ctx.beginPath()
                        ctx.moveTo(mapArea.mouseX - 5, mapArea.mouseY - 5)
                        ctx.lineTo(mapArea.mouseX,     mapArea.mouseY)
                        ctx.lineTo(mapArea.mouseX + 5, mapArea.mouseY - 5)
                        ctx.closePath()
                        ctx.fillStyle = Qt.rgba(0.13, 0.79, 0.26, 0.45)
                        ctx.fill()
                    }
                }
            }

            // ── Add-marker mode banner ─────────────────────────────────────────
            Rectangle {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 8 }
                visible:  root.addMarkerMode
                width:    bannerText.width + 24; height: 26; radius: 13
                color:    "#22c55e"
                Text {
                    id: bannerText
                    anchors.centerIn: parent
                    text: "Click map to place marker"
                    color: "white"; font.pixelSize: 11; font.bold: true
                }
            }

            // ── Mouse area ────────────────────────────────────────────────────
            MouseArea {
                id: mapArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  root.addMarkerMode ? Qt.CrossCursor : Qt.ArrowCursor

                onPositionChanged: function(mouse) {
                    if (root.addMarkerMode) overlayCanvas.requestPaint()
                    if (!pressed) return

                    var dx = mouse.x - root.dragStartX
                    var dy = mouse.y - root.dragStartY
                    if (!root.isDragging && (Math.abs(dx) > 3 || Math.abs(dy) > 3))
                        root.isDragging = true

                    if (root.isDragging) {
                        // Translate tile layers instantly — no network requests during drag
                        tileLayer.panBy(dx, dy)

                        // Update logical center so overlay paints correctly
                        var ts    = 256
                        var scale = Math.pow(2, root.zoom) * ts
                        root.centerLng = root.dragStartLng - dx / scale * 360
                        var cPy = (1 - Math.log(Math.tan(Math.PI/4 + root.dragStartLat*Math.PI/360))/Math.PI) / 2
                        var nPy = Math.max(0.001, Math.min(0.999, cPy - dy / scale))
                        root.centerLat = 180/Math.PI * (2*Math.atan(Math.exp((1-2*nPy)*Math.PI)) - Math.PI/2)
                        overlayCanvas.requestPaint()
                    }
                }

                onReleased: function(mouse) {
                    if (root.isDragging) {
                        // Pan ended — reload tiles at new center
                        tileLayer.fullRefresh()
                        overlayCanvas.requestPaint()
                    } else {
                        // It was a click
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

                onPressed: function(mouse) {
                    root.dragStartX   = mouse.x
                    root.dragStartY   = mouse.y
                    root.dragStartLat = root.centerLat
                    root.dragStartLng = root.centerLng
                    root.isDragging   = false
                    markerPopup.visible = false
                }

                onWheel: function(wheel) {
                    var delta   = wheel.angleDelta.y > 0 ? 1 : -1
                    var newZoom = Math.max(1, Math.min(19, root.zoom + delta))
                    if (newZoom !== root.zoom) {
                        root.zoom = newZoom
                        tileLayer.fullRefresh()
                        overlayCanvas.requestPaint()
                    }
                }
            }

            // ── Marker label popup ────────────────────────────────────────────
            Rectangle {
                id: markerPopup
                visible:  false
                z:        200
                width:    200; height: 70; radius: 8
                color:    ThemeManager.surfaceColor
                border.color: "#22c55e"; border.width: 1.5

                property real   pendingLat: 0
                property real   pendingLng: 0
                property alias  labelField: lblInput

                Column {
                    anchors { fill: parent; margins: 10 }
                    spacing: 6

                    Text { text: "Marker label (optional)"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }

                    Row {
                        spacing: 6; width: parent.width
                        Rectangle {
                            width: parent.width - 56; height: 24; radius: 4
                            color: ThemeManager.backgroundColor
                            border.color: ThemeManager.borderColor
                            TextInput {
                                id: lblInput
                                anchors { fill: parent; leftMargin: 7; rightMargin: 7; topMargin: 4; bottomMargin: 4 }
                                color: ThemeManager.textColor; font.pixelSize: 11
                                Keys.onReturnPressed:  markerPopup.confirm()
                                Keys.onEscapePressed:  markerPopup.visible = false
                            }
                        }
                        Rectangle {
                            width: 50; height: 24; radius: 4
                            color: "#22c55e"
                            Text { anchors.centerIn: parent; text: "Add"; color: "white"; font.pixelSize: 10; font.bold: true }
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
                    text: (behaviourObject ? behaviourObject.markerCount : 0) + " markers"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                }
                Text {
                    text: (behaviourObject ? behaviourObject.traceLength  : 0) + " trace pts"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.centerLat.toFixed(5) + ",  " + root.centerLng.toFixed(5)
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                    font.family: "Consolas, monospace"
                }
            }
        }
    }
}
