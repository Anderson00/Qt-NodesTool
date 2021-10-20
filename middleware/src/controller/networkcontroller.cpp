#include "networkcontroller.h"

NetworkController::NetworkController(QObject *parent) : QObject(parent),
    m_server(new TCPServer(this))
{
    QObject::connect(m_server, &TCPServer::newClient, this, &NetworkController::processNewClient);
    QObject::connect(m_server, &TCPServer::newMessage, this, &NetworkController::processNewMessage);
}

NetworkController::~NetworkController()
{
    this->m_server->close();
}

Client *NetworkController::getClient(const QString &ip, int port)
{
    for(Client *client : this->m_clients){
        if(client->ip() == ip && client->port() == port){
            return client;
        }
    }

    return nullptr;
}

void NetworkController::processNewClient(QTcpSocket *client)
{
    this->m_clients.push_back(new Client(client, this));
    emit clientConnected(this->m_clients.front());
}

void NetworkController::processNewMessage(QTcpSocket *client, QJsonObject message)
{
    Client *sourceClient = this->getClient(client->peerAddress().toString(), client->peerPort());
    if(sourceClient == nullptr){
        qInfo() << "Unknow client"
                << client->peerAddress().toString().append(":").append(client->peerPort())
                << "may be a bug, client not registred in list"
                << "may be a Hacker!";
        return;
    }
    emit messageReceived(sourceClient, message);
}
