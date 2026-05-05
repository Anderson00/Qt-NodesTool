#include "linechartviewer.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(LineChartViewer, "Line Chart", "Advanced XY line chart with multi-series, zoom/pan and live stats", "common", 13, 0)

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

// ── Public slots → emit internal signals consumed by QML ─────────────────────
void LineChartViewer::appendXY(double x, double y)                        { emit internalAppendXY(x, y); }
void LineChartViewer::appendYAutoIncrementX(double y)                     { emit internalappendYAutoIncrementX(y); }
void LineChartViewer::appendYAutoIncrementXChannel2(double y)              { emit internalAppendYAutoIncrementXChannel2(y); }
void LineChartViewer::appendXYToSeries(int seriesIdx, double x, double y) { emit internalAppendXYToSeries(seriesIdx, x, y); }
void LineChartViewer::appendYToSeries(int seriesIdx, double y)            { emit internalAppendYToSeries(seriesIdx, y); }
void LineChartViewer::clearChart()                                        { emit internalClearChart(); }
void LineChartViewer::clearSeries(int seriesIdx)                          { emit internalClearSeries(seriesIdx); }
void LineChartViewer::setXRange(double min, double max)                   { emit internalSetXRange(min, max); }
void LineChartViewer::setYRange(double min, double max)                   { emit internalSetYRange(min, max); }
void LineChartViewer::resetZoom()                                         { emit internalResetZoom(); }

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
