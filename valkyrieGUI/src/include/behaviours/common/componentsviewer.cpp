#include "componentsviewer.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(ComponentsViewer, "Components Viewer", "All Components and test tool", "common", 0, 0)

ComponentsViewer::ComponentsViewer(QObject *parent)
{

    this->setWidth(700);
    this->setHeight(500);
    this->setContentHeight(500);
    this->setQmlBodyUrl("qrc:/behaviours/common/ComponentsViewer.qml");
}

QMap<QString, QVariant> ComponentsViewer::loadInfos()
{
    return ComponentsViewer::static_infos();
}

QMap<QString, QVariant> ComponentsViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name", "ComponentsViewer"},
        {"type", Behaviours::Type::CPP},
        {"className", "ComponentsViewer"},
        {"desc", "All Componentes and test tool"},
        {"inputs_count", "0"},
        {"outputs_count", "0"}
    });
}
