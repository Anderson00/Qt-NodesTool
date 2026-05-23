#include "barchartviewer.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(BarChartViewer, "Bar Chart", "Multi-series bar chart with auto-scaling Y axis", "Charts", 0, 0)

BarChartViewer::BarChartViewer(QObject *parent) : Behaviours(parent)
{
    this->setWidth(320);
    this->setHeight(340);
    this->setContentHeight(340);
    this->setQmlBodyUrl("qrc:/behaviours/common/BarChartViewer.qml");
}

QMap<QString, QVariant> BarChartViewer::loadInfos()
{
    return BarChartViewer::static_infos();
}

QMap<QString, QVariant> BarChartViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "BarChartViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "BarChartViewer"},
        {"desc",          "Multi-series bar chart"},
        {"inputs_count",  "0"},
        {"outputs_count", "0"}
    });
}

void BarChartViewer::appendToSet(int setIndex, double value)
{
    emit internalAppendToSet(setIndex, value);
}

void BarChartViewer::addSet(const QString& name)
{
    emit internalAddSet(name);
}

void BarChartViewer::clearChart()
{
    emit internalClearChart();
}

QJsonObject BarChartViewer::saveState() const
{
    return QJsonObject();
}

void BarChartViewer::loadState(const QJsonObject&)
{
}
