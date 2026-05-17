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
    property int    zoom:      behaviourObject ? behaviourObject.zoom : 13

    property var    markers:   []
    property var    trace:     []

    // drag state
    property real dragStartX: 0
    property real dragStartY: 0
    property real dragStartLat: 0
    property real dragStartLng: 0

    // ── Tile math (Web Mercator) ───────────────────────────────────────────────
    function lon2tile(lng, z) { return Math.floor((lng + 180) / 360 * Math.pow(2, z)) }
    function lat2tile(lat, z) {
        return Math.floor((1 - Math.log(Math.tan(lat * Math.PI/180) +
               1/Math.cos(lat * Math.PI/180)) / Math.PI) / 2 * Math.pow(2, z))
    }
    function tile2lon(x, z) { return x / Math.pow(2,z) * 360 - 180 }
    function tile2lat(y, z) {
        var n = Math.PI - 2*Math.PI*y/Math.pow(2,z)
        return 180/Math.PI * Math.atan(0.5*(Math.exp(n)-Math.exp(-n)))
    }

    // project lat/lng to pixel coords relative to map center
    function latLngToPixel(lat, lng) {
        var tileSize = 256
        var scale = Math.pow(2, zoom) * tileSize
        var n = Math.PI - 2*Math.PI*lat/180
        var py = Math.log(Math.tan(Math.PI/4 + lat*Math.PI/360)) / Math.PI
        var centerPy = Math.log(Math.tan(Math.PI/4 + centerLat*Math.PI/360)) / Math.PI

        var px = (lng + 180) / 360 * scale
        var pxCenter = (centerLng + 180) / 360 * scale
        var mapPy = (1 - py) / 2 * scale
        var mapPyCenter = (1 - centerPy) / 2 * scale

        return Qt.point(
            mapCanvas.width/2  + (px - pxCenter),
            mapCanvas.height/2 + (mapPy - mapPyCenter)
        )
    }

    Connections {
        target: behaviourObject
        function onInternalMarkersChanged() { refreshMarkers() }
        function onInternalTraceChanged()   { refreshTrace() }
        function onInternalCenterChanged(lat, lng, z) {
            root.centerLat = lat; root.centerLng = lng; root.zoom = z
            tileGrid.refresh(); overlayCanvas.requestPaint()
        }
        function onInternalClear() { root.markers = []; root.trace = []; tileGrid.refresh(); overlayCanvas.requestPaint() }
    }

    function refreshMarkers() {
        if (behaviourObject) root.markers = behaviourObject.getMarkers()
        overlayCanvas.requestPaint()
    }
    function refreshTrace() {
        if (behaviourObject) root.trace = behaviourObject.getTrace()
        overlayCanvas.requestPaint()
    }

    Component.onCompleted: { tileGrid.refresh() }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 32
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                spacing: 6

                Text { text: "Map Viewer"; color: ThemeManager.textColor; font.pixelSize: 11; font.bold: true }

                Item { Layout.fillWidth: true }

                // Zoom controls
                Text { text: "Zoom:"; color: ThemeManager.textSecondaryColor; font.pixelSize: 10 }
                Rectangle {
                    width: 22; height: 22; radius: 4; color: ThemeManager.backgroundColor
                    border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "−"; color: ThemeManager.textColor; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: { if (root.zoom > 1) { root.zoom--; tileGrid.refresh(); overlayCanvas.requestPaint() } } }
                }
                Text { text: root.zoom; color: ThemeManager.textColor; font.pixelSize: 11; width: 22; horizontalAlignment: Text.AlignHCenter }
                Rectangle {
                    width: 22; height: 22; radius: 4; color: ThemeManager.backgroundColor
                    border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "+"; color: ThemeManager.textColor; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: { if (root.zoom < 19) { root.zoom++; tileGrid.refresh(); overlayCanvas.requestPaint() } } }
                }

                Rectangle {
                    width: 50; height: 22; radius: 4
                    color: ThemeManager.backgroundColor; border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "Clear"; color: ThemeManager.textSecondaryColor; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; onClicked: { if (behaviourObject) behaviourObject.clearAll() } }
                }
            }
        }

        // ── Map area ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#a8c8f0"
            clip: true

            // Tile grid
            Item {
                id: tileGrid
                anchors.fill: parent

                property var tileItems: []

                function refresh() {
                    // Clear old tiles
                    for (var i = 0; i < tileItems.length; i++) tileItems[i].destroy()
                    tileItems = []

                    var tileSize = 256
                    var centerTileX = root.lon2tile(root.centerLng, root.zoom)
                    var centerTileY = root.lat2tile(root.centerLat, root.zoom)
                    var tilesWide = Math.ceil(width  / tileSize) + 2
                    var tilesTall = Math.ceil(height / tileSize) + 2

                    // pixel offset of center tile from widget center
                    var maxTile = Math.pow(2, root.zoom)
                    var centerTilePxX = (centerTileX + 0.5) * tileSize
                    var totalPxX = (root.centerLng + 180) / 360 * maxTile * tileSize
                    var offsetX = width/2 - (totalPxX - centerTileX * tileSize)

                    var n = Math.PI - 2*Math.PI*root.centerLat/180
                    var centerPy = (1 - Math.log(Math.tan(Math.PI/4 + root.centerLat*Math.PI/360))/Math.PI) / 2
                    var totalPxY = centerPy * maxTile * tileSize
                    var offsetY = height/2 - (totalPxY - centerTileY * tileSize)

                    for (var dx = -Math.floor(tilesWide/2); dx <= Math.ceil(tilesWide/2); dx++) {
                        for (var dy = -Math.floor(tilesTall/2); dy <= Math.ceil(tilesTall/2); dy++) {
                            var tx = ((centerTileX + dx) % maxTile + maxTile) % maxTile
                            var ty = centerTileY + dy
                            if (ty < 0 || ty >= maxTile) continue
                            var comp = Qt.createComponent("qrc:/components/Image.qml") // fallback: use Image directly
                            var px = (centerTileX + dx) * tileSize + offsetX
                            var py = (centerTileY + dy) * tileSize + offsetY
                            var obj = tileComp.createObject(tileGrid, {
                                x: px, y: py, width: tileSize, height: tileSize,
                                source: "https://tile.openstreetmap.org/" + root.zoom + "/" + tx + "/" + ty + ".png"
                            })
                            if (obj) tileItems.push(obj)
                        }
                    }
                }

                Component {
                    id: tileComp
                    Image {
                        width: 256; height: 256
                        fillMode: Image.Stretch
                        cache: true
                        smooth: true
                    }
                }
            }

            // Overlay canvas for markers and trace
            Canvas {
                id: overlayCanvas
                anchors.fill: parent

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    // Draw trace
                    var trace = root.trace
                    if (trace.length > 1) {
                        ctx.beginPath()
                        ctx.strokeStyle = "#3b82f6"
                        ctx.lineWidth = 3
                        ctx.lineJoin = "round"
                        var pt0 = root.latLngToPixel(trace[0].lat, trace[0].lng)
                        ctx.moveTo(pt0.x, pt0.y)
                        for (var i = 1; i < trace.length; i++) {
                            var pt = root.latLngToPixel(trace[i].lat, trace[i].lng)
                            ctx.lineTo(pt.x, pt.y)
                        }
                        ctx.stroke()
                    }

                    // Draw markers
                    var markers = root.markers
                    for (var j = 0; j < markers.length; j++) {
                        var m = markers[j]
                        var mpt = root.latLngToPixel(m.lat, m.lng)
                        var mcolor = m.type === "start" ? "#22c55e" :
                                     m.type === "end"   ? "#ef4444" : "#6366f1"

                        ctx.beginPath()
                        ctx.arc(mpt.x, mpt.y, 8, 0, 2*Math.PI)
                        ctx.fillStyle = mcolor
                        ctx.fill()
                        ctx.strokeStyle = "white"
                        ctx.lineWidth = 2
                        ctx.stroke()

                        // Label
                        if (m.label) {
                            ctx.fillStyle = ThemeManager.textColor
                            ctx.font = "10px sans-serif"
                            ctx.fillText(m.label, mpt.x + 10, mpt.y - 4)
                        }
                    }
                }
            }

            // Mouse interaction
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                onPressed: function(mouse) {
                    root.dragStartX = mouse.x
                    root.dragStartY = mouse.y
                    root.dragStartLat = root.centerLat
                    root.dragStartLng = root.centerLng
                }

                onPositionChanged: function(mouse) {
                    if (pressed) {
                        var tileSize = 256
                        var scale = Math.pow(2, root.zoom) * tileSize
                        var dx = mouse.x - root.dragStartX
                        var dy = mouse.y - root.dragStartY
                        root.centerLng = root.dragStartLng - dx / scale * 360
                        var centerPy = (1 - Math.log(Math.tan(Math.PI/4 + root.dragStartLat*Math.PI/360))/Math.PI) / 2
                        var newPy = centerPy - dy / scale
                        newPy = Math.max(0.001, Math.min(0.999, newPy))
                        root.centerLat = 180/Math.PI * (2*Math.atan(Math.exp((1-2*newPy)*Math.PI)) - Math.PI/2)
                        tileGrid.refresh()
                        overlayCanvas.requestPaint()
                    }
                }

                onWheel: function(wheel) {
                    var delta = wheel.angleDelta.y > 0 ? 1 : -1
                    var newZoom = Math.max(1, Math.min(19, root.zoom + delta))
                    if (newZoom !== root.zoom) {
                        root.zoom = newZoom
                        tileGrid.refresh()
                        overlayCanvas.requestPaint()
                    }
                }

                onClicked: function(mouse) {
                    if (behaviourObject) {
                        // approx lat/lng from click
                        var tileSize = 256
                        var scale = Math.pow(2, root.zoom) * tileSize
                        var dx = mouse.x - width/2
                        var dy = mouse.y - height/2
                        var lng = root.centerLng + dx / scale * 360
                        var centerPy = (1 - Math.log(Math.tan(Math.PI/4 + root.centerLat*Math.PI/360))/Math.PI) / 2
                        var newPy = centerPy + dy / scale
                        newPy = Math.max(0.001, Math.min(0.999, newPy))
                        var lat = 180/Math.PI * (2*Math.atan(Math.exp((1-2*newPy)*Math.PI)) - Math.PI/2)
                        behaviourObject.mapClicked(lat, lng)
                    }
                }
            }
        }

        // ── Status bar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 22
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: "📍 " + (behaviourObject ? behaviourObject.markerCount : 0) + " markers"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                }
                Text {
                    text: "✦ " + (behaviourObject ? behaviourObject.traceLength : 0) + " trace pts"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.centerLat.toFixed(4) + ", " + root.centerLng.toFixed(4)
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                    font.family: "monospace"
                }
            }
        }
    }
}
