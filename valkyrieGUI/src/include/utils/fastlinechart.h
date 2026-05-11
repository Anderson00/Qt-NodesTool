#pragma once
#include <QQuickItem>
#include <QColor>
#include <QVector>
#include <QPointF>
#include <QVariantList>

class FastLineChart : public QQuickItem
{
    Q_OBJECT

    // ── Left / bottom axes ────────────────────────────────────────────────
    Q_PROPERTY(double xMin      READ xMin      WRITE setXMin      NOTIFY xRangeChanged)
    Q_PROPERTY(double xMax      READ xMax      WRITE setXMax      NOTIFY xRangeChanged)
    Q_PROPERTY(double yMin      READ yMin      WRITE setYMin      NOTIFY yRangeChanged)
    Q_PROPERTY(double yMax      READ yMax      WRITE setYMax      NOTIFY yRangeChanged)
    // ── Right Y axis ──────────────────────────────────────────────────────
    Q_PROPERTY(double yRightMin  READ yRightMin  WRITE setYRightMin  NOTIFY yRightRangeChanged)
    Q_PROPERTY(double yRightMax  READ yRightMax  WRITE setYRightMax  NOTIFY yRightRangeChanged)
    Q_PROPERTY(bool   hasRightAxis READ hasRightAxis NOTIFY yRightRangeChanged)
    // ── Behaviour ─────────────────────────────────────────────────────────
    Q_PROPERTY(bool   autoScale  READ autoScale  WRITE setAutoScale  NOTIFY autoScaleChanged)
    Q_PROPERTY(int    maxPoints  READ maxPoints  WRITE setMaxPoints   NOTIFY maxPointsChanged)
    Q_PROPERTY(double oscilloscopeWindow READ oscilloscopeWindow WRITE setOscilloscopeWindow NOTIFY oscilloscopeChanged)
    // ── Appearance ────────────────────────────────────────────────────────
    Q_PROPERTY(bool   antialias  READ antialias  WRITE setAntialias   NOTIFY appearanceChanged)
    Q_PROPERTY(QColor gridColor  READ gridColor  WRITE setGridColor   NOTIFY appearanceChanged)
    Q_PROPERTY(int    gridCountX READ gridCountX WRITE setGridCountX  NOTIFY appearanceChanged)
    Q_PROPERTY(int    gridCountY READ gridCountY WRITE setGridCountY  NOTIFY appearanceChanged)
    Q_PROPERTY(qreal  lineWidth  READ lineWidth  WRITE setLineWidth   NOTIFY appearanceChanged)
    // ── Read-only outputs for QML overlays ────────────────────────────────
    Q_PROPERTY(int           seriesCount READ seriesCount NOTIFY seriesCountChanged)
    Q_PROPERTY(QVariantList  xTicks      READ xTicks      NOTIFY ticksChanged)
    Q_PROPERTY(QVariantList  yTicks      READ yTicks      NOTIFY ticksChanged)
    Q_PROPERTY(QVariantList  yRightTicks READ yRightTicks NOTIFY ticksChanged)
    Q_PROPERTY(QVariantList  refLines    READ refLines    NOTIFY overlayChanged)
    Q_PROPERTY(QVariantList  markers     READ markers     NOTIFY overlayChanged)

public:
    explicit FastLineChart(QQuickItem *parent = nullptr);

    // ── Getters ───────────────────────────────────────────────────────────
    double xMin() const      { return m_xMin; }
    double xMax() const      { return m_xMax; }
    double yMin() const      { return m_yMin; }
    double yMax() const      { return m_yMax; }
    double yRightMin() const { return m_yRightMin; }
    double yRightMax() const { return m_yRightMax; }
    bool   hasRightAxis() const  { return m_hasRightAxis; }
    bool   autoScale() const { return m_autoScale; }
    int    maxPoints() const { return m_maxPoints; }
    double oscilloscopeWindow() const { return m_oscWindow; }
    bool   antialias() const { return m_antialias; }
    QColor gridColor()  const { return m_gridColor; }
    int    gridCountX() const { return m_gridCountX; }
    int    gridCountY() const { return m_gridCountY; }
    qreal  lineWidth()  const { return m_lineWidth; }
    int    seriesCount() const { return m_series.size(); }
    QVariantList xTicks()      const { return m_xTicks; }
    QVariantList yTicks()      const { return m_yTicks; }
    QVariantList yRightTicks() const { return m_yRightTicks; }
    QVariantList refLines()    const { return m_refLinesInfo; }
    QVariantList markers()     const { return m_markersInfo; }

    // ── Series ────────────────────────────────────────────────────────────
    Q_INVOKABLE int     addSeries(const QString &name, const QColor &color);
    Q_INVOKABLE void    appendPoint(int idx, double x, double y);
    Q_INVOKABLE void    appendPointAutoX(int idx, double y);
    Q_INVOKABLE void    clearSeries(int idx);
    Q_INVOKABLE void    clearAll();
    Q_INVOKABLE void    setSeriesColor(int idx, const QColor &c);
    Q_INVOKABLE QColor  seriesColor(int idx) const;
    Q_INVOKABLE void    setSeriesName(int idx, const QString &name);
    Q_INVOKABLE QString seriesName(int idx) const;
    Q_INVOKABLE void    setSeriesVisible(int idx, bool visible);
    Q_INVOKABLE bool    seriesVisible(int idx) const;
    Q_INVOKABLE void    setSeriesFillOpacity(int idx, float opacity);
    Q_INVOKABLE void    setSeriesUseRightAxis(int idx, bool useRight);
    Q_INVOKABLE void    setSeriesMovingAvg(int idx, int window, const QColor &color);
    Q_INVOKABLE int     pointCount(int idx) const;

    // ── Overlays ──────────────────────────────────────────────────────────
    Q_INVOKABLE void addHLine(double y,   const QColor &c, const QString &label = {});
    Q_INVOKABLE void addVLine(double x,   const QColor &c, const QString &label = {});
    Q_INVOKABLE void clearRefLines();
    Q_INVOKABLE void addMarker(double x,  const QColor &c, const QString &label = {});
    Q_INVOKABLE void clearMarkers();

    // ── View helpers ──────────────────────────────────────────────────────
    Q_INVOKABLE void    setXRange(double min, double max);
    Q_INVOKABLE void    setYRange(double min, double max);
    Q_INVOKABLE void    setYRightRange(double min, double max);
    // Returns the data-space point on series `idx` nearest to screen-X `sx`.
    Q_INVOKABLE QPointF nearestPoint(int idx, float sx) const;
    // Async grab — saves PNG to `path` once the render thread completes.
    Q_INVOKABLE void    grabToFile(const QString &path);

public slots:
    void setXMin(double v);   void setXMax(double v);
    void setYMin(double v);   void setYMax(double v);
    void setYRightMin(double v); void setYRightMax(double v);
    void setAutoScale(bool v);
    void setMaxPoints(int v);
    void setOscilloscopeWindow(double w);
    void setAntialias(bool v);
    void setGridColor(const QColor &c);
    void setGridCountX(int n); void setGridCountY(int n);
    void setLineWidth(qreal w);

signals:
    void xRangeChanged();
    void yRangeChanged();
    void yRightRangeChanged();
    void autoScaleChanged();
    void maxPointsChanged();
    void oscilloscopeChanged();
    void appearanceChanged();
    void seriesCountChanged();
    void ticksChanged();
    void overlayChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &, const QRectF &) override;

private:
    struct SeriesData {
        QString          name;
        QVector<QPointF> points;
        QColor           color     = QColor("#e74c3c");
        bool             visible   = true;
        float            fillOpa   = 0.0f;
        bool             rightAxis = false;
        int              mavgWin   = 0;
        QColor           mavgColor = QColor(255, 255, 255, 140);
        // Incremental Y extremes to avoid O(n) scan on every append
        double           yMin = qInf(), yMax = -qInf();
        bool             needsRescan = false;
    };

    struct RefLine  { double value; bool isH; QColor color; QString label; };
    struct Marker   { double x;             QColor color; QString label; };

    void ensureSeries(int idx);
    void markDirty();
    void recomputeAutoScale();
    void recomputeTicks();
    void rebuildOverlayInfo();

    static QVector<double> niceTickValues(double min, double max, int n);
    static double niceNum(double x, bool doRound);
    // buildRibbon / screenDedup are free static helpers in the .cpp —
    // they use QSGGeometry types that must not appear in the header.

    QVector<SeriesData> m_series;
    QVector<RefLine>    m_refLines;
    QVector<Marker>     m_markers;

    // These are rebuilt in rebuildOverlayInfo() and exposed as Q_PROPERTYs
    QVariantList m_refLinesInfo;
    QVariantList m_markersInfo;

    double m_xMin = 0.0,  m_xMax = 10.0;
    double m_yMin = -1.0, m_yMax = 1.0;
    double m_yRightMin = -1.0, m_yRightMax = 1.0;
    bool   m_hasRightAxis = false;
    bool   m_autoScale    = true;
    int    m_maxPoints    = 500;
    double m_oscWindow    = 0.0;
    bool   m_antialias    = true;
    QColor m_gridColor    = QColor(255, 255, 255, 30);
    int    m_gridCountX   = 5, m_gridCountY = 5;
    qreal  m_lineWidth    = 2.0;

    QVariantList m_xTicks, m_yTicks, m_yRightTicks;
    bool m_dirty = false;

    static const QColor kDefaultColors[8];
};
