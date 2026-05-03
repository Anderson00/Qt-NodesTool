import QtQuick 2.12
import App.Theme 1.0

// Viewport-fixed canvas that draws the infinite dot grid, workspace boundary,
// origin axis lines and 500-unit tick marks.
// All drawing is in screen-space so no large texture is allocated.
Canvas {
    id: root

    // Position of the workspace Item top-left corner in viewport coordinates.
    property real panX: 0
    property real panY: 0

    // Current zoom factor.
    property real zoom: 1

    // Workspace dimensions (must match the Item that holds the nodes).
    property real canvasWidth:  10000
    property real canvasHeight: 10000

    // Minor grid cell size in world units.
    property int minWgrid: 20

    // Grid pattern: "dots" | "lines" | "circles" | "cross" | "hexagon" | "none"
    property string pattern: "dots"
    onPatternChanged:  requestPaint()
    onMinWgridChanged: requestPaint()

    z: 0

    onPanXChanged:    requestPaint()
    onPanYChanged:    requestPaint()
    onZoomChanged:    requestPaint()
    onWidthChanged:   requestPaint()
    onHeightChanged:  requestPaint()

    Connections {
        target: ThemeManager
        function onThemeChanged() { root.requestPaint() }
    }

    onPaint: {
        var ctx   = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        var z     = zoom
        var cell  = minWgrid * z
        var major = cell * 5
        var pc    = ThemeManager.primaryColor
        var px    = panX
        var py    = panY

        var ox  = ((px % cell)  + cell)  % cell
        var oy  = ((py % cell)  + cell)  % cell
        var mox = ((px % major) + major) % major
        var moy = ((py % major) + major) % major

        if (pattern === "dots") {
            // ── Minor dots (LOD: only when cell ≥ 32 px) ────────────────────────
            if (cell >= 32) {
                var mr = Math.max(0.9, z * 0.48)
                ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.20)
                ctx.beginPath()
                for (var ix = ox; ix <= width  + cell; ix += cell) {
                    for (var iy = oy; iy <= height + cell; iy += cell) {
                        ctx.moveTo(ix + mr, iy)
                        ctx.arc(ix, iy, mr, 0, 6.2832)
                    }
                }
                ctx.fill()
            }

            // ── Major dots ──────────────────────────────────────────────────────
            var xr = Math.max(1.4, z * 0.88)
            ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.48)
            ctx.beginPath()
            for (var jx = mox; jx <= width  + major; jx += major) {
                for (var jy = moy; jy <= height + major; jy += major) {
                    ctx.moveTo(jx + xr, jy)
                    ctx.arc(jx, jy, xr, 0, 6.2832)
                }
            }
            ctx.fill()

        } else if (pattern === "lines") {
            // ── Minor lines (LOD: only when cell ≥ 32 px) ───────────────────────
            ctx.lineWidth = 1
            if (cell >= 32) {
                ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.12)
                ctx.beginPath()
                for (var lx = ox; lx <= width + cell; lx += cell) {
                    ctx.moveTo(lx, 0); ctx.lineTo(lx, height)
                }
                for (var ly = oy; ly <= height + cell; ly += cell) {
                    ctx.moveTo(0, ly); ctx.lineTo(width, ly)
                }
                ctx.stroke()
            }

            // ── Major lines ──────────────────────────────────────────────────────
            ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.22)
            ctx.beginPath()
            for (var mlx = mox; mlx <= width + major; mlx += major) {
                ctx.moveTo(mlx, 0); ctx.lineTo(mlx, height)
            }
            for (var mly = moy; mly <= height + major; mly += major) {
                ctx.moveTo(0, mly); ctx.lineTo(width, mly)
            }
            ctx.stroke()

        } else if (pattern === "circles") {
            // ── Minor tiny dots (LOD: only when cell ≥ 32 px) ───────────────────
            if (cell >= 32) {
                var cmr = Math.max(0.9, z * 0.48)
                ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.20)
                ctx.beginPath()
                for (var cix = ox; cix <= width  + cell; cix += cell) {
                    for (var ciy = oy; ciy <= height + cell; ciy += cell) {
                        ctx.moveTo(cix + cmr, ciy)
                        ctx.arc(cix, ciy, cmr, 0, 6.2832)
                    }
                }
                ctx.fill()
            }

            // ── Major hollow circles ─────────────────────────────────────────────
            var cr = cell * 0.35
            ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.18)
            ctx.lineWidth = 1
            ctx.beginPath()
            for (var cjx = mox; cjx <= width  + major; cjx += major) {
                for (var cjy = moy; cjy <= height + major; cjy += major) {
                    ctx.moveTo(cjx + cr, cjy)
                    ctx.arc(cjx, cjy, cr, 0, 6.2832)
                }
            }
            ctx.stroke()

        } else if (pattern === "cross") {
            // ── Minor crosses (LOD: only when cell ≥ 32 px) ─────────────────────
            var half = cell * 0.14
            if (cell >= 32) {
                ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.15)
                ctx.lineWidth = 1
                ctx.beginPath()
                for (var xix = ox; xix <= width  + cell; xix += cell) {
                    for (var xiy = oy; xiy <= height + cell; xiy += cell) {
                        ctx.moveTo(xix - half, xiy); ctx.lineTo(xix + half, xiy)
                        ctx.moveTo(xix, xiy - half); ctx.lineTo(xix, xiy + half)
                    }
                }
                ctx.stroke()
            }

            // ── Major crosses ────────────────────────────────────────────────────
            var xhalf = cell * 0.14
            ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.35)
            ctx.lineWidth = 1
            ctx.beginPath()
            for (var xjx = mox; xjx <= width  + major; xjx += major) {
                for (var xjy = moy; xjy <= height + major; xjy += major) {
                    ctx.moveTo(xjx - xhalf, xjy); ctx.lineTo(xjx + xhalf, xjy)
                    ctx.moveTo(xjx, xjy - xhalf); ctx.lineTo(xjx, xjy + xhalf)
                }
            }
            ctx.stroke()

        } else if (pattern === "hexagon") {
            // ── Hexagons at major grid intersections (pointy-top) ────────────────
            var hexSize = major * 0.42
            ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.22)
            ctx.lineWidth = 1
            ctx.beginPath()
            for (var hx = mox; hx <= width  + major; hx += major) {
                for (var hy = moy; hy <= height + major; hy += major) {
                    for (var hi = 0; hi < 6; hi++) {
                        var angle = (Math.PI / 180) * (60 * hi - 30)
                        var hpx = hx + hexSize * Math.cos(angle)
                        var hpy = hy + hexSize * Math.sin(angle)
                        if (hi === 0) ctx.moveTo(hpx, hpy)
                        else          ctx.lineTo(hpx, hpy)
                    }
                    ctx.closePath()
                }
            }
            ctx.stroke()

        }
        // pattern === "none": skip all grid drawing

        // ── Workspace boundary ───────────────────────────────────────────────
        var bL = px
        var bT = py
        var bR = px + canvasWidth  * z
        var bB = py + canvasHeight * z

        var anyEdgeVisible = (bL > 0 && bL < width)  ||
                             (bR > 0 && bR < width)  ||
                             (bT > 0 && bT < height) ||
                             (bB > 0 && bB < height)

        if (anyEdgeVisible) {
            var cL = Math.max(0, bL)
            var cT = Math.max(0, bT)
            var cR = Math.min(width,  bR)
            var cB = Math.min(height, bB)

            ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.55)
            ctx.lineWidth   = 1.5
            ctx.setLineDash([7, 5])
            ctx.beginPath()
            if (bL >= 0 && bL <= width)  { ctx.moveTo(bL, cT); ctx.lineTo(bL, cB) }
            if (bR >= 0 && bR <= width)  { ctx.moveTo(bR, cT); ctx.lineTo(bR, cB) }
            if (bT >= 0 && bT <= height) { ctx.moveTo(cL, bT); ctx.lineTo(cR, bT) }
            if (bB >= 0 && bB <= height) { ctx.moveTo(cL, bB); ctx.lineTo(cR, bB) }
            ctx.stroke()
            ctx.setLineDash([])

            ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.40)
            ctx.font = "10px sans-serif"
            if (bL >= 2 && bL <= width - 20 && bT >= 2 && bT <= height - 14)
                ctx.fillText("⌜", bL + 3, bT + 12)
            if (bR >= 20 && bR <= width - 2 && bT >= 2 && bT <= height - 14)
                ctx.fillText("⌝", bR - 13, bT + 12)
            if (bL >= 2 && bL <= width - 20 && bB >= 14 && bB <= height - 2)
                ctx.fillText("⌞", bL + 3, bB - 3)
            if (bR >= 20 && bR <= width - 2 && bB >= 14 && bB <= height - 2)
                ctx.fillText("⌟", bR - 13, bB - 3)
        }

        // ── Axis lines and 500-unit tick marks ───────────────────────────────
        // World origin (0,0) maps to canvas position (5000, 5000).
        var ox5  = px + 5000 * z
        var oy5  = py + 5000 * z
        var step = 500 * z

        ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.22)
        ctx.lineWidth = 1
        ctx.setLineDash([])
        if (oy5 >= 0 && oy5 <= height) {
            ctx.beginPath(); ctx.moveTo(0, oy5); ctx.lineTo(width, oy5); ctx.stroke()
        }
        if (ox5 >= 0 && ox5 <= width) {
            ctx.beginPath(); ctx.moveTo(ox5, 0); ctx.lineTo(ox5, height); ctx.stroke()
        }

        ctx.font = "9px sans-serif"
        var tickLen = 5

        // Horizontal ticks (along X axis)
        if (oy5 >= 0 && oy5 <= height) {
            var startTX = ox5 % step
            if (startTX < 0) startTX += step
            for (var tx = startTX; tx <= width + step; tx += step) {
                var worldX = Math.round((tx - ox5) / z)
                if (worldX % 500 !== 0) continue
                ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, worldX === 0 ? 0.0 : 0.38)
                ctx.lineWidth = 1
                ctx.beginPath(); ctx.moveTo(tx, oy5 - tickLen); ctx.lineTo(tx, oy5 + tickLen); ctx.stroke()
                if (worldX !== 0 && tx > 4 && tx < width - 4) {
                    ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.38)
                    ctx.textAlign = "center"
                    ctx.fillText(worldX, tx, oy5 - tickLen - 3)
                }
            }
        }

        // Vertical ticks (along Y axis)
        if (ox5 >= 0 && ox5 <= width) {
            var startTY = oy5 % step
            if (startTY < 0) startTY += step
            for (var ty = startTY; ty <= height + step; ty += step) {
                var worldY = Math.round((ty - oy5) / z)
                if (worldY % 500 !== 0) continue
                ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, worldY === 0 ? 0.0 : 0.38)
                ctx.lineWidth = 1
                ctx.beginPath(); ctx.moveTo(ox5 - tickLen, ty); ctx.lineTo(ox5 + tickLen, ty); ctx.stroke()
                if (worldY !== 0 && ty > 10 && ty < height - 4) {
                    ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.38)
                    ctx.textAlign = "left"
                    ctx.fillText(worldY, ox5 + tickLen + 3, ty + 3)
                }
            }
        }
    }
}
