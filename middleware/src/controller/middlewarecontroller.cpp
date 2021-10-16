#include "middlewarecontroller.h"

MiddlewareController::MiddlewareController(OperationMode mode, QObject *parent) : QObject(parent),
    m_mode(mode)
{
    init();
}

void MiddlewareController::init()
{
    switch (m_mode) {
    case Lan:{
        m_network_controller = new NetworkController(nullptr);
        // TODO: connect signals
    }
        break;
    case Network:
        qDebug() << "Network mode not implemented";
        break;
    case Api:
        qDebug() << "Api mode not implemented";
        break;
    }
}
