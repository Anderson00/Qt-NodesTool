#include "middlewarecontroller.h"
#include <QCoreApplication>

MiddlewareController::MiddlewareController(OperationMode mode, QObject *parent) : QObject(parent),
    m_mode(mode)
{
    init();
}

void MiddlewareController::init()
{
    qDebug() << "Middleware initialization, mode:" << m_mode;

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
        emit quit();
        break;
    case Api:
        qDebug() << "Api mode not implemented";
        emit quit();
        break;
    case RestApi:
        qDebug() << "RestApi mode not implemented";
        emit quit();
        break;
    case Unknow:
        qCritical() << "Unknow type of operation";
        emit quit();
        break;
    }
}

void MiddlewareController::processAgentConnection(Agente *source)
{
    this->m_agentes.push_back(source);
}

void MiddlewareController::processRequest(Agente *source, QJsonObject request)
{

}
