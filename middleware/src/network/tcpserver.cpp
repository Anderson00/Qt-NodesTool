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

        QObject::connect(client, &QTcpSocket::disconnected, this, [&](){
            this->m_clients.removeOne(client);
        });

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
}

void TCPServer::close()
{
    this->m_server->close();
}

void TCPServer::processTCPMessage(QTcpSocket *client, const QByteArray& bytes)
{
    QJsonDocument doc = QJsonDocument::fromJson(bytes);
    if(doc.isNull() || doc.isEmpty() || !doc.isObject()){
        qDebug() << "Client InvalidJSON:"
                 << client->peerAddress().toString().append(":").append(client->peerPort())
                 << bytes;
        // TODO: send JSON error to client
        //       this->sendMessage(client, errorInvalidJson);
        return;
    }
    emit newMessage(client, doc.object());
}

void TCPServer::sendMessage(QTcpSocket *destination, QJsonObject message)
{
    if(destination != nullptr)
        destination->write(QJsonDocument(message).toJson(QJsonDocument::Compact));
    else
        qDebug() << "Null pointer Destination(*QTcpSocket)";
}

void TCPServer::sendToAll(QList<QTcpSocket*> clients, QJsonObject message)
{
    for(QTcpSocket *tcpConn : qAsConst(clients)){
        sendMessage(tcpConn, message);
    }
}

void TCPServer::sendToAll(QJsonObject message)
{
    sendToAll(this->m_clients, message);
}
