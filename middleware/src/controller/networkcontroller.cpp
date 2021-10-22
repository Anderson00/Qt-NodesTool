#include "networkcontroller.h"
#include <QTimer>

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
    for(Client *client : qAsConst(this->m_clients)){
        if(client->ip() == ip && client->port() == port){
            return client;
        }
    }

    return nullptr;
}

void NetworkController::processNewClient(QTcpSocket *client)
{
    Client *newClient = new Client(client, this);
    processClientReconnection(newClient);

    QObject::connect(newClient, &Client::disconnected, this, [&](){
        processClientDisconnection(newClient);
    }, Qt::QueuedConnection);

    this->m_clients.push_back(newClient);
    emit clientConnected(newClient);
}

void NetworkController::processClientReconnection(Client *client)
{
    Client *clientDisconnected = getClientDisconnected(client);

    if(clientDisconnected != nullptr){
        client->params(clientDisconnected->params());
    }
}

void NetworkController::processClientDisconnection(Client *client)
{

    this->m_clientsDisconected.push_back(client);
    QTimer *timer = new QTimer(this);
    timer->setSingleShot(true);
    timer->setInterval(300000); // 5 minutes
    QObject::connect(timer, &QTimer::timeout, [&](){
        qDebug() << "Clearing client data"
                 << client->toString();
        this->m_clientsDisconected.removeOne(client);
        this->m_reconnectionTimeout.removeOne(timer);
        delete timer;
    });
    this->m_reconnectionTimeout.push_back(timer);
    timer->start();
    emit clientDisconnect(client);
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

Client *NetworkController::getClientDisconnected(const Client *client)
{
    for(Client *clientDisc : this->m_clientsDisconected){
        if(clientDisc == client){
            return clientDisc;
        }
    }

    return nullptr;
}
