#ifndef LINECHARTVIEWER_H
#define LINECHARTVIEWER_H

#include <QObject>
#include <QTimer>
#include <QVector>
#include <QVariantList>
#include <behaviours/behaviours.h>

class LineChartViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int     maxPoints  READ maxPoints  WRITE setMaxPoints  NOTIFY maxPointsChanged)
    Q_PROPERTY(bool    autoScale  READ autoScale  WRITE setAutoScale  NOTIFY autoScaleChanged)
    Q_PROPERTY(QString chartTitle READ chartTitle WRITE setChartTitle NOTIFY chartTitleChanged)

public:
    explicit LineChartViewer(QObject *parent = nullptr);

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int     maxPoints()  const;
    bool    autoScale()  const;
    QString chartTitle() const;

public slots:
    // ── Primary series (index 0) ──────────────────────────────────────────
    void appendXY(double x, double y);
    void appendYAutoIncrementX(double y);
    void appendYAutoIncrementXChannel2(double y);

    // ── Multi-series ──────────────────────────────────────────────────────
    void appendXYToSeries(int seriesIdx, double x, double y);
    void appendYToSeries(int seriesIdx, double y);

    // ── Clear ─────────────────────────────────────────────────────────────
    void clearChart();
    void clearSeries(int seriesIdx);

    // ── Axis / view control ───────────────────────────────────────────────
    void setXRange(double min, double max);
    void setYRange(double min, double max);
    void resetZoom();

    // ── Settings (also reflected as Q_PROPERTYs) ─────────────────────────
    void setMaxPoints(int max);
    void setAutoScale(bool enabled);
    void setChartTitle(const QString &title);

    // ── Universal data input ──────────────────────────────────────────────
    // Accepts a QVariantList of 1–3 elements:
    //   [y]             → appendYAutoIncrementX(y)
    //   [x, y]          → appendXY(x, y)
    //   [series, x, y]  → appendXYToSeries(series, x, y)
    void setInputData(const QVariantList& data);

    // ── QML batch helper ──────────────────────────────────────────────────
    // QML's LineSeries only exposes single-point replace overloads.
    // This invokable calls QXYSeries::replace(QList<QPointF>) directly,
    // which emits pointsReplaced once → one updateGeometry() instead of N.
    Q_INVOKABLE void replaceSeriesPoints(QObject *series, const QVariantList &points);

signals:
    // Internal — forwarded to QML; excluded from node I/O
    void internalAppendXY(double x, double y);
    void internalappendYAutoIncrementX(double y);
    void internalAppendYAutoIncrementXChannel2(double y);
    void internalAppendXYToSeries(int seriesIdx, double x, double y);
    void internalAppendYToSeries(int seriesIdx, double y);
    void internalClearChart();
    void internalClearSeries(int seriesIdx);
    void internalSetXRange(double min, double max);
    void internalSetYRange(double min, double max);
    void internalResetZoom();

    // Property notifiers
    void maxPointsChanged();
    void autoScaleChanged();
    void chartTitleChanged();

private slots:
    void flushPending();

private:
    enum PendingOp { AppendXY, AppendYAuto };
    struct PendingPoint {
        PendingOp op;
        int       series;
        double    x;
        double    y;
    };

    QTimer               m_flushTimer;
    QVector<PendingPoint> m_pending;

    int     m_maxPoints  = 500;
    bool    m_autoScale  = true;
    QString m_chartTitle;
};

#endif // LINECHARTVIEWER_H
