#include "piechartviewer.h"
#include "behaviours/behaviourregistry.h"
#include <QVariantList>

REGISTER_BEHAVIOUR(PieChartViewer, "Pie Chart", "Interactive pie/donut chart with dynamic slices", "Charts", 0, 0)

PieChartViewer::PieChartViewer(QObject *parent) : Behaviours(parent)
{
    this->setWidth(320);
    this->setHeight(340);
    this->setContentHeight(340);
    this->setQmlBodyUrl("qrc:/behaviours/common/PieChartViewer.qml");
}

QMap<QString, QVariant> PieChartViewer::loadInfos()
{
    return PieChartViewer::static_infos();
}

QMap<QString, QVariant> PieChartViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "PieChartViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "PieChartViewer"},
        {"desc",          "Interactive pie/donut chart"},
        {"inputs_count",  "0"},
        {"outputs_count", "0"}
    });
}

void PieChartViewer::addSlice(const QString& label, double value)
{
    emit internalAddSlice(label, value);
}

void PieChartViewer::setSliceValue(int index, double value)
{
    emit internalSetSliceValue(index, value);
}

void PieChartViewer::clearSlices()
{
    emit internalClearSlices();
}

void PieChartViewer::removeSlice(int index)
{
    emit internalRemoveSlice(index);
}

void PieChartViewer::setInputData(const QVariantList& data)
{
    if (data.isEmpty()) return;
    if (data.size() == 1) {
        addSlice(QString(), data[0].toDouble());
    } else {
        addSlice(data[0].toString(), data[1].toDouble());
    }
}

QJsonObject PieChartViewer::saveState() const
{
    return QJsonObject();
}

void PieChartViewer::loadState(const QJsonObject&)
{
}
