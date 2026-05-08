#include "hub.h"
#include <behaviours/connections.h>
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(Hub, "Hub", "Send information and broadcasts all data across each connection", "logic", 1, 0)

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
