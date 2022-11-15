#include "linechartviewer.h"

LineChartViewer::LineChartViewer(QObject *parent)
{
    this->setWidth(500);
    this->setHeight(300);
    this->setContentHeight(300);
    this->setQmlBodyUrl("qrc:/behaviours/common/LineChartViewer.qml");
    this->addInputOutputExclusion(QList<QString>({
                                                    "internalAppendXY(double,double)",
                                                    "internalappendYAutoIncrementX(double)"
                                                 }));
}

QMap<QString, QVariant> LineChartViewer::loadInfos()
{
    return LineChartViewer::static_infos();
}

QMap<QString, QVariant> LineChartViewer::static_infos()
{
    return QMap<QString, QVariant>({
                                       {"name", "LineChartViewer"},
                                       {"type", Behaviours::Type::CPP},
                                       {"className", "LineChartViewer"},
                                       {"desc", "Show Line chart XY"},
                                       {"inputs_count", "2"},
                                       {"outputs_count", "0"}
                                   });
}

void LineChartViewer::appendXY(double x, double y)
{
    emit internalAppendXY(x, y);
}

void LineChartViewer::appendYAutoIncrementX(double y)
{
    emit internalappendYAutoIncrementX(y);
}
