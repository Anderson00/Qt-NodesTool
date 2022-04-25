#include "hub.h"
#include <behaviours/connections.h>

Hub::Hub(QObject *parent) : Behaviours(parent)
{
    this->setWidth(150);
    //this->setHeight(100);
    //this->setContentHeight(150);
    //this->setQmlBodyUrl("qrc:/behaviours/common/FileOpener.qml");
    this->addInputOutputExclusion(QList<QString>({

                                                 }));
}

QMap<QString, QVariant> Hub::loadInfos()
{
    return Hub::static_infos();
}

QMap<QString, QVariant> Hub::static_infos()
{
    return QMap<QString, QVariant>({
                                       {"name", "Hub"},
                                       {"type", Behaviours::Type::CPP},
                                       {"className", "Hub"},
                                       {"desc", "Send information and broadcasts all data across each connection"},
                                       {"inputs_count", "1"},
                                       {"outputs_count", "*"}
                                   });
}

void Hub::input(QByteArray variant)
{

}
