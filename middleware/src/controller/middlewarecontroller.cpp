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
        m_network_controller = new NetworkController(this);
        // TODO: connect signals
        QObject::connect(m_network_controller, &NetworkController::clientConnected, this, &MiddlewareController::processAgentConnection);
        QObject::connect(m_network_controller, &NetworkController::messageReceived, this, &MiddlewareController::processRequest);

    }
        break;
    case Network:
        qDebug() << "Network mode not implemented";
        break;
    case Api:
        qDebug() << "Api mode not implemented";
        break;
    case RestApi:
        qDebug() << "RestApi mode not implemented";
        break;
    }
}

void MiddlewareController::processAgentConnection(Agente *source)
{

}

void MiddlewareController::processRequest(Agente *source, QJsonObject request)
{

}
