#include "radarchartviewer.h"
#include "behaviours/behaviourregistry.h"

#include <QJsonArray>

REGISTER_BEHAVIOUR(RadarChartViewer, "Radar Chart", "Spider/radar chart for multi-dimensional data comparison", "Charts", 4, 1)

RadarChartViewer::RadarChartViewer(QObject *parent)
    : Behaviours(parent)
{
    setWidth(340);
    setHeight(360);
    setContentHeight(360);
    setQmlBodyUrl("qrc:/behaviours/visualization/RadarChartViewer.qml");

    addInputOutputExclusion(QList<QString>({
        "internalDataChanged()",
        "internalClear()"
    }));
}

QMap<QString, QVariant> RadarChartViewer::loadInfos()
{
    return RadarChartViewer::static_infos();
}

QMap<QString, QVariant> RadarChartViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "RadarChartViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "RadarChartViewer"},
        {"desc",          "Spider/radar chart for multi-dimensional data comparison"},
        {"inputs_count",  "4"},
        {"outputs_count", "1"}
    });
}

void RadarChartViewer::setShowGrid(bool v)
{
    if (m_showGrid != v) {
        m_showGrid = v;
        emit showGridChanged();
        emit internalDataChanged();
    }
}

void RadarChartViewer::setFillOpacity(double v)
{
    if (m_fillOpacity != v) {
        m_fillOpacity = v;
        emit fillOpacityChanged();
        emit internalDataChanged();
    }
}

QVariantList RadarChartViewer::getSeriesData() const
{
    QVariantList result;
    for (const auto& pair : m_series) {
        QVariantMap entry;
        entry["name"]   = pair.first;
        entry["values"] = pair.second;
        result.append(entry);
    }
    return result;
}

QStringList RadarChartViewer::getLabels() const
{
    return m_labels;
}

void RadarChartViewer::setValues(QVariantList values)
{
    if (m_series.isEmpty()) {
        m_series.append(qMakePair(QString("Series 1"), values));
    } else {
        m_series[0].second = values;
    }
    recalcMax();
    emit seriesCountChanged();
    emit internalDataChanged();
}

void RadarChartViewer::setLabels(QStringList labels)
{
    m_labels = labels;
    emit internalDataChanged();
}

void RadarChartViewer::addSeries(QString name, QVariantList values)
{
    m_series.append(qMakePair(name, values));
    recalcMax();
    emit seriesCountChanged();
    emit internalDataChanged();
}

void RadarChartViewer::clear()
{
    m_series.clear();
    m_labels.clear();
    m_maxValue = 1.0;
    emit seriesCountChanged();
    emit maxValueChanged();
    emit internalClear();
}

void RadarChartViewer::recalcMax()
{
    double mx = 1.0;
    for (const auto& pair : m_series) {
        for (const QVariant& v : pair.second) {
            double val = v.toDouble();
            if (val > mx) mx = val;
        }
    }
    if (mx != m_maxValue) {
        m_maxValue = mx;
        emit maxValueChanged();
    }
}

QJsonObject RadarChartViewer::saveState() const
{
    QJsonObject state;
    state["showGrid"]    = m_showGrid;
    state["fillOpacity"] = m_fillOpacity;

    QJsonArray labelsArr;
    for (const QString& l : m_labels)
        labelsArr.append(l);
    state["labels"] = labelsArr;

    QJsonArray seriesArr;
    for (const auto& pair : m_series) {
        QJsonObject s;
        s["name"] = pair.first;
        QJsonArray vals;
        for (const QVariant& v : pair.second)
            vals.append(v.toDouble());
        s["values"] = vals;
        seriesArr.append(s);
    }
    state["series"] = seriesArr;
    return state;
}

void RadarChartViewer::loadState(const QJsonObject& state)
{
    if (state.contains("showGrid"))    setShowGrid(state["showGrid"].toBool(true));
    if (state.contains("fillOpacity")) setFillOpacity(state["fillOpacity"].toDouble(0.3));

    if (state.contains("labels")) {
        QStringList labels;
        for (const auto& v : state["labels"].toArray())
            labels.append(v.toString());
        m_labels = labels;
    }

    if (state.contains("series")) {
        m_series.clear();
        for (const auto& sv : state["series"].toArray()) {
            QJsonObject s = sv.toObject();
            QVariantList vals;
            for (const auto& v : s["values"].toArray())
                vals.append(v.toDouble());
            m_series.append(qMakePair(s["name"].toString(), vals));
        }
        recalcMax();
    }

    emit seriesCountChanged();
    emit internalDataChanged();
}
