#ifndef LINECHARTVIEWER_H
#define LINECHARTVIEWER_H

#include <QObject>
#include <behaviours/behaviours.h>

class LineChartViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int     maxPoints  READ maxPoints  WRITE setMaxPoints  NOTIFY maxPointsChanged)
    Q_PROPERTY(bool    autoScale  READ autoScale  WRITE setAutoScale  NOTIFY autoScaleChanged)
    Q_PROPERTY(QString chartTitle READ chartTitle WRITE setChartTitle NOTIFY chartTitleChanged)

public:
    explicit LineChartViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

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

private:
    int     m_maxPoints  = 500;
    bool    m_autoScale  = true;
    QString m_chartTitle;
};

#endif // LINECHARTVIEWER_H
