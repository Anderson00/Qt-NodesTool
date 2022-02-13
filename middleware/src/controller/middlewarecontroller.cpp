#include "middlewarecontroller.h"
#include <QCoreApplication>
#include <QDir>
#include <QVariant>
#include <src/utils.h>

MiddlewareController::MiddlewareController(OperationMode mode, const QString &filesPath, QObject *parent) : QObject(parent),
    m_mode(mode),
    m_files_path(filesPath),
    m_command_controller(new CommandController(this))
{
    if(!QDir(m_files_path).exists())
        m_files_path = "";

    if(filesPath.isEmpty())
        QDir(".").mkdir(mid::filesDirName); // create input files directory
    init();
}

QStringList MiddlewareController::filesList() const
{
    QDir dir((m_files_path.isEmpty())? mid::filesDirName : m_files_path);
    return dir.entryList({"*.exe"}, QDir::Files | QDir::NoDot | QDir::NoDotDot);
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
        QObject::connect(m_command_controller, &CommandController::resultReady, [this](Agente *agente, QJsonObject result) {
            Client *clientAgente = this->m_network_controller->getClient(agente->uuid());
            this->m_network_controller->sendMessage(clientAgente, result);
        });
    }
        break;
    case Network:
        qDebug() << "Network mode not implemented";
        assert(false);
        break;
    case Api:
        qDebug() << "Api mode not implemented";
        assert(false);
        break;
    case RestApi:
        qDebug() << "RestApi mode not implemented";
        assert(false);
        break;
    case Unknow:
        qCritical() << "Unknow type of operation";
        assert(false);
        break;
    }
}

void MiddlewareController::processAgentConnection(Agente *source)
{
    this->m_agentes.push_back(source);
}

void MiddlewareController::executeCommand(Agente *client, QJsonObject message)
{
    this->m_command_controller->executeCmd(client, message["cmd"].toString(""), message["params"].toArray());
}

void MiddlewareController::processRequest(Agente *source, QJsonObject request)
{
    if(request.contains("cmd")){
        this->executeCommand(source, request);
    }
}
