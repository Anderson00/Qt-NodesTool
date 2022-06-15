#include "processesviewer.h"

ProcessesViewer::ProcessesViewer(QObject *parent)
{
    this->setWidth(500);
    this->setHeight(300);
    this->setContentHeight(150);
    this->setQmlBodyUrl("qrc:/behaviours/common/ProcessesViewer.qml");
    this->addInputOutputExclusion(QList<QString>({

                                                 }));
}

QMap<QString, QVariant> ProcessesViewer::loadInfos()
{
    return ProcessesViewer::static_infos();
}

QMap<QString, QVariant> ProcessesViewer::static_infos()
{
    return QMap<QString, QVariant>({
                                       {"name", "ProcessesViewer"},
                                       {"type", Behaviours::Type::CPP},
                                       {"className", "ProcessesViewer"},
                                       {"desc", "Retrieves the process identifier for each process object in the system."},
                                       {"inputs_count", "0"},
                                       {"outputs_count", "1"}
                                   });
}
