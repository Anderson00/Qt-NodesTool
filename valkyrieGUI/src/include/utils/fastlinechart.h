#pragma once
#include <QQuickItem>
#include <QColor>
#include <QVector>
#include <QPointF>
#include <QVariantList>

// FastLineChart — QQuickItem that renders directly through the Qt Quick Scene Graph.
//
// Rationale: QtCharts' QLineSeries calls updateGeometry() for every pointAdded signal,
// recalculating all screen-space coordinates on each insertion. This class bypasses that
// entirely: data is held in a plain QVector and transformed to vertex coordinates once per
// frame inside updatePaintNode() (render thread, main thread blocked — no mutex needed).
//
// Line rendering uses DrawTriangleStrip (2 vertices per point forming a ribbon), which is
// portable across all Qt RHI backends including Direct3D where GL_LINE_WIDTH is unavailable.

class FastLineChart : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(double xMin      READ xMin      WRITE setXMin      NOTIFY xRangeChanged)
    Q_PROPERTY(double xMax      READ xMax      WRITE setXMax      NOTIFY xRangeChanged)
    Q_PROPERTY(double yMin      READ yMin      WRITE setYMin      NOTIFY yRangeChanged)
    Q_PROPERTY(double yMax      READ yMax      WRITE setYMax      NOTIFY yRangeChanged)
    Q_PROPERTY(bool   autoScale READ autoScale WRITE setAutoScale NOTIFY autoScaleChanged)
    Q_PROPERTY(int    maxPoints READ maxPoints WRITE setMaxPoints  NOTIFY maxPointsChanged)
    Q_PROPERTY(QColor gridColor  READ gridColor  WRITE setGridColor  NOTIFY appearanceChanged)
    Q_PROPERTY(int    gridCountX READ gridCountX WRITE setGridCountX NOTIFY appearanceChanged)
    Q_PROPERTY(int    gridCountY READ gridCountY WRITE setGridCountY NOTIFY appearanceChanged)
    Q_PROPERTY(qreal  lineWidth  READ lineWidth  WRITE setLineWidth  NOTIFY appearanceChanged)
    Q_PROPERTY(QVariantList xTicks READ xTicks NOTIFY ticksChanged)
    Q_PROPERTY(QVariantList yTicks READ yTicks NOTIFY ticksChanged)

public:
    explicit FastLineChart(QQuickItem *parent = nullptr);

    double xMin()      const { return m_xMin; }
    double xMax()      const { return m_xMax; }
    double yMin()      const { return m_yMin; }
    double yMax()      const { return m_yMax; }
    bool   autoScale() const { return m_autoScale; }
    int    maxPoints() const { return m_maxPoints; }
    QColor gridColor()  const { return m_gridColor; }
    int    gridCountX() const { return m_gridCountX; }
    int    gridCountY() const { return m_gridCountY; }
    qreal  lineWidth()  const { return m_lineWidth; }
    QVariantList xTicks() const { return m_xTicks; }
    QVariantList yTicks() const { return m_yTicks; }

    Q_INVOKABLE void appendPoint(int seriesIdx, double x, double y);
    Q_INVOKABLE void appendPointAutoX(int seriesIdx, double y);
    Q_INVOKABLE void clearSeries(int seriesIdx);
    Q_INVOKABLE void clearAll();
    Q_INVOKABLE void setSeriesColor(int seriesIdx, const QColor &color);
    Q_INVOKABLE int  pointCount(int seriesIdx) const;

public slots:
    void setXMin(double v);
    void setXMax(double v);
    void setYMin(double v);
    void setYMax(double v);
    void setXRange(double min, double max);
    void setYRange(double min, double max);
    void setAutoScale(bool enabled);
    void setMaxPoints(int max);
    void setGridColor(const QColor &c);
    void setGridCountX(int n);
    void setGridCountY(int n);
    void setLineWidth(qreal w);

signals:
    void xRangeChanged();
    void yRangeChanged();
    void autoScaleChanged();
    void maxPointsChanged();
    void appearanceChanged();
    void ticksChanged();

protected:
    QSGNode *updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) override;
    void geometryChange(const QRectF &newGeometry, const QRectF &oldGeometry) override;

private:
    void recomputeAutoScale();
    void recomputeTicks();
    void markDirty();
    void ensureSeries(int idx);

    static QVector<double> niceTickValues(double min, double max, int targetCount);
    static double niceNum(double x, bool doRound);

    struct SeriesData {
        QVector<QPointF> points;
        QColor           color;
        // Incremental extremes — avoids full rescan on every append.
        // Reset to invalid when a point that was the extreme is removed.
        // qInf() avoids std::numeric_limits which conflicts with Windows max/min macros.
        double yMin =  qInf();
        double yMax = -qInf();
        bool   needsRescan = false;
    };

    QVector<SeriesData> m_series;

    double m_xMin = 0.0,  m_xMax = 10.0;
    double m_yMin = -1.0, m_yMax = 1.0;
    bool   m_autoScale  = true;
    int    m_maxPoints  = 500;
    QColor m_gridColor  = QColor(255, 255, 255, 30);
    int    m_gridCountX = 5;
    int    m_gridCountY = 5;
    qreal  m_lineWidth  = 2.0;

    QVariantList m_xTicks;
    QVariantList m_yTicks;
    bool m_dirty = false;

    static const QColor kDefaultColors[8];
};
