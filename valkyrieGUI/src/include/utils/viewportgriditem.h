#pragma once
#include <QQuickItem>
#include <QColor>
#include <QVariantList>

// Direct Scene Graph replacement for ViewportGridCanvas.qml (Canvas-based).
//
// Why: The Canvas item re-executes a JS drawing routine on every pan/zoom
// frame, including QPainter CPU rasterization + texture upload. This item
// instead fills a plain float vertex buffer on every frame and lets the GPU
// draw everything — no rasterization, no JS, no texture upload.
//
// Feature parity: all 7 patterns (dots, lines, circles, cross, x, hexagon,
// none), workspace boundary dashes, origin axis lines + 500-unit tick marks.
// Tick labels and boundary corner glyphs are exposed as QVariantList
// properties so the companion ViewportGridSGG.qml can place QML Text items.
//
// Threading: updatePaintNode() runs on the render thread while the main
// thread is blocked (Qt's sync step) — direct m_* reads are safe. All
// QVariantList properties used by QML are updated on the main thread inside
// the property setters via recomputeOverlayInfo().

class ViewportGridItem : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(qreal   panX         READ panX         WRITE setPanX         NOTIFY panXChanged)
    Q_PROPERTY(qreal   panY         READ panY         WRITE setPanY         NOTIFY panYChanged)
    Q_PROPERTY(qreal   zoom         READ zoom         WRITE setZoom         NOTIFY zoomChanged)
    Q_PROPERTY(int     minWgrid     READ minWgrid     WRITE setMinWgrid     NOTIFY gridChanged)
    Q_PROPERTY(QString pattern      READ pattern      WRITE setPattern      NOTIFY gridChanged)
    Q_PROPERTY(qreal   canvasWidth  READ canvasWidth  WRITE setCanvasWidth  NOTIFY canvasSizeChanged)
    Q_PROPERTY(qreal   canvasHeight READ canvasHeight WRITE setCanvasHeight NOTIFY canvasSizeChanged)
    Q_PROPERTY(QColor  primaryColor READ primaryColor WRITE setPrimaryColor NOTIFY primaryColorChanged)

    // ── QML text-overlay outputs (updated on main thread) ────────────────
    Q_PROPERTY(qreal        axisXScreenY   READ axisXScreenY   NOTIFY overlayChanged)
    Q_PROPERTY(qreal        axisYScreenX   READ axisYScreenX   NOTIFY overlayChanged)
    Q_PROPERTY(QVariantList xAxisTicks     READ xAxisTicks     NOTIFY overlayChanged)
    Q_PROPERTY(QVariantList yAxisTicks     READ yAxisTicks     NOTIFY overlayChanged)
    Q_PROPERTY(QVariantList boundaryCorners READ boundaryCorners NOTIFY overlayChanged)

public:
    explicit ViewportGridItem(QQuickItem *parent = nullptr);

    qreal   panX()         const { return m_panX; }
    qreal   panY()         const { return m_panY; }
    qreal   zoom()         const { return m_zoom; }
    int     minWgrid()     const { return m_minWgrid; }
    QString pattern()      const { return m_pattern; }
    qreal   canvasWidth()  const { return m_canvasWidth; }
    qreal   canvasHeight() const { return m_canvasHeight; }
    QColor  primaryColor() const { return m_primaryColor; }

    qreal        axisXScreenY()    const { return m_axisXScreenY; }
    qreal        axisYScreenX()    const { return m_axisYScreenX; }
    QVariantList xAxisTicks()      const { return m_xAxisTicks; }
    QVariantList yAxisTicks()      const { return m_yAxisTicks; }
    QVariantList boundaryCorners() const { return m_boundaryCorners; }

public slots:
    void setPanX(qreal v);
    void setPanY(qreal v);
    void setZoom(qreal v);
    void setMinWgrid(int v);
    void setPattern(const QString &v);
    void setCanvasWidth(qreal v);
    void setCanvasHeight(qreal v);
    void setPrimaryColor(const QColor &c);

signals:
    void panXChanged();
    void panYChanged();
    void zoomChanged();
    void gridChanged();
    void canvasSizeChanged();
    void primaryColorChanged();
    void overlayChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &, const QRectF &) override;

private:
    void markDirty();
    void recomputeOverlayInfo();  // main-thread: ticks, boundary corners

    qreal   m_panX         = 0;
    qreal   m_panY         = 0;
    qreal   m_zoom         = 1;
    int     m_minWgrid     = 20;
    QString m_pattern      = "dots";
    qreal   m_canvasWidth  = 10000;
    qreal   m_canvasHeight = 10000;
    QColor  m_primaryColor = QColor("#3498db");

    // Overlay info (main thread only)
    qreal        m_axisXScreenY  = -1;
    qreal        m_axisYScreenX  = -1;
    QVariantList m_xAxisTicks;
    QVariantList m_yAxisTicks;
    QVariantList m_boundaryCorners;

    bool m_dirty = false;
};
