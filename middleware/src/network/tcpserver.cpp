#include "tcpserver.h"
#include <src/utils.h>
#include <QJsonDocument>

TCPServer::TCPServer(QObject *parent) : QObject(parent),
    m_server(new QTcpServer(this))
{
    if(!m_server->listen(QHostAddress::Any, mid::network::TCP_SERVER_PORT)){
        qDebug() << m_server->errorString();
        abort();
    }

    QObject::connect(m_server, &QTcpServer::newConnection, this, [&](){
        QTcpSocket *client = this->m_server->nextPendingConnection();
        this->m_clients.push_back(client);

        QObject::connect(client, &QTcpSocket::readyRead, this, [&](){
            processTCPMessage(client, client->readAll());
        });
        emit newClient(client);
    });
}

TCPServer::~TCPServer()
{
    this->m_server->close();
    delete this->m_server;

    for(auto client : this->m_clients){
        delete client;
    }
}

void TCPServer::processTCPMessage(QTcpSocket *client, const QByteArray &bytes)
{
    QJsonDocument doc = QJsonDocument::fromJson(bytes);
    if(doc.isNull() || doc.isEmpty() || !doc.isObject()){
        qDebug() << "Client InvalidJSON:" << client->peerAddress().toString().append(":").append(client->peerPort()) << bytes;
        // TODO: send JSON error to client
        return;
    }
    emit newMessage(client, doc.object());
}
