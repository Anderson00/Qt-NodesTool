#include "linechartviewer.h"
#include "behaviours/behaviourregistry.h"
#include <QtCharts/QXYSeries>

REGISTER_BEHAVIOUR(LineChartViewer, "Line Chart", "Advanced XY line chart with multi-series, zoom/pan and live stats", "Charts", 13, 0)

LineChartViewer::LineChartViewer(QObject *parent)
{
    this->setWidth(560);
    this->setHeight(420);
    this->setContentHeight(420);
    this->setQmlBodyUrl("qrc:/behaviours/common/LineChartViewer.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalAppendXY(double,double)",
        "internalappendYAutoIncrementX(double)",
        "internalAppendYAutoIncrementXChannel2(double)",
        "internalAppendXYToSeries(int,double,double)",
        "internalAppendYToSeries(int,double)",
        "internalClearChart()",
        "internalClearSeries(int)",
        "internalSetXRange(double,double)",
        "internalSetYRange(double,double)",
        "internalResetZoom()"
    }));

    // Flush buffered points to QML at ~60 fps instead of on every incoming data signal.
    // This decouples a high-frequency data source (e.g. 1 kHz timer) from the render rate.
    m_flushTimer.setInterval(16);
    m_flushTimer.setTimerType(Qt::CoarseTimer);
    connect(&m_flushTimer, &QTimer::timeout, this, &LineChartViewer::flushPending);
    m_flushTimer.start();
}

void LineChartViewer::onPinsReady()
{
    // inputs
    setPinTypeForSignature("appendXY(double,double)",              Connections::AnyType);
    setPinTypeForSignature("appendYAutoIncrementX(double)",        Connections::DoubleType);
    setPinTypeForSignature("appendYAutoIncrementXChannel2(double)",Connections::DoubleType);
    setPinTypeForSignature("appendXYToSeries(int,double,double)",  Connections::AnyType);
    setPinTypeForSignature("appendYToSeries(int,double)",          Connections::AnyType);
    setPinTypeForSignature("clearChart()",                         Connections::FlowType);
    setPinTypeForSignature("clearSeries(int)",                     Connections::IntType);
    setPinTypeForSignature("setXRange(double,double)",             Connections::AnyType);
    setPinTypeForSignature("setYRange(double,double)",             Connections::AnyType);
    setPinTypeForSignature("resetZoom()",                          Connections::FlowType);
    setPinTypeForSignature("setMaxPoints(int)",                    Connections::IntType);
    setPinTypeForSignature("setAutoScale(bool)",                   Connections::BoolType);
    setPinTypeForSignature("setInputData(QVariantList)",           Connections::ArrayType);
    // no node outputs — all signals are internal QML bridge
}

QMap<QString, QVariant> LineChartViewer::loadInfos()
{
    return LineChartViewer::static_infos();
}

QMap<QString, QVariant> LineChartViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "LineChartViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "LineChartViewer"},
        {"desc",          "Advanced XY line chart with multi-series, zoom/pan and live stats"},
        {"inputs_count",  "13"},
        {"outputs_count", "0"}
    });
}

// ── Property accessors ────────────────────────────────────────────────────────
int     LineChartViewer::maxPoints()  const { return m_maxPoints; }
bool    LineChartViewer::autoScale()  const { return m_autoScale; }
QString LineChartViewer::chartTitle() const { return m_chartTitle; }

// ── Public slots → buffer data points; other ops emit immediately ─────────────

// Data append slots: push into pending buffer; flushed to QML by m_flushTimer.
void LineChartViewer::appendXY(double x, double y)
    { m_pending.append({AppendXY,   0,         x,   y}); }
void LineChartViewer::appendYAutoIncrementX(double y)
    { m_pending.append({AppendYAuto, 0,        0.0, y}); }
void LineChartViewer::appendYAutoIncrementXChannel2(double y)
    { m_pending.append({AppendYAuto, 1,        0.0, y}); }
void LineChartViewer::appendXYToSeries(int seriesIdx, double x, double y)
    { m_pending.append({AppendXY,   seriesIdx,  x,   y}); }
void LineChartViewer::appendYToSeries(int seriesIdx, double y)
    { m_pending.append({AppendYAuto, seriesIdx, 0.0, y}); }

// Non-data ops are immediate so that clear/range changes take effect right away.
void LineChartViewer::clearChart() {
    m_pending.clear();
    emit internalClearChart();
}
void LineChartViewer::clearSeries(int seriesIdx) {
    m_pending.removeIf([seriesIdx](const PendingPoint &p){ return p.series == seriesIdx; });
    emit internalClearSeries(seriesIdx);
}
void LineChartViewer::setXRange(double min, double max) { emit internalSetXRange(min, max); }
void LineChartViewer::setYRange(double min, double max) { emit internalSetYRange(min, max); }
void LineChartViewer::resetZoom()                       { emit internalResetZoom(); }

// ── Flush: emit all pending points to QML in one synchronous burst ────────────
void LineChartViewer::flushPending() {
    if (m_pending.isEmpty()) return;
    QVector<PendingPoint> pts;
    pts.swap(m_pending);
    for (const auto &p : std::as_const(pts)) {
        if (p.op == AppendXY)
            emit internalAppendXYToSeries(p.series, p.x, p.y);
        else
            emit internalAppendYToSeries(p.series, p.y);
    }
}

void LineChartViewer::setMaxPoints(int max)
{
    if (m_maxPoints != max) {
        m_maxPoints = max;
        emit maxPointsChanged();
    }
}

void LineChartViewer::setAutoScale(bool enabled)
{
    if (m_autoScale != enabled) {
        m_autoScale = enabled;
        emit autoScaleChanged();
    }
}

void LineChartViewer::setChartTitle(const QString &title)
{
    if (m_chartTitle != title) {
        m_chartTitle = title;
        emit chartTitleChanged();
    }
}

void LineChartViewer::setInputData(const QVariantList& data)
{
    if (data.size() == 1) {
        appendYAutoIncrementX(data[0].toDouble());
    } else if (data.size() == 2) {
        appendXY(data[0].toDouble(), data[1].toDouble());
    } else if (data.size() >= 3) {
        appendXYToSeries(data[0].toInt(), data[1].toDouble(), data[2].toDouble());
    }
}

void LineChartViewer::replaceSeriesPoints(QObject *series, const QVariantList &points)
{
    auto *xySeries = qobject_cast<QXYSeries *>(series);
    if (!xySeries) return;
    QList<QPointF> pts;
    pts.reserve(points.size());
    for (const QVariant &v : points)
        pts.append(v.toPointF());
    xySeries->replace(pts);
}

QJsonObject LineChartViewer::saveState() const {
    QJsonObject state;
    state["maxPoints"]  = m_maxPoints;
    state["autoScale"]  = m_autoScale;
    if (!m_chartTitle.isEmpty())
        state["chartTitle"] = m_chartTitle;
    return state;
}

void LineChartViewer::loadState(const QJsonObject& state) {
    if (state.contains("maxPoints"))
        setMaxPoints(state["maxPoints"].toInt(500));
    if (state.contains("autoScale"))
        setAutoScale(state["autoScale"].toBool(true));
    if (state.contains("chartTitle"))
        setChartTitle(state["chartTitle"].toString());
}
