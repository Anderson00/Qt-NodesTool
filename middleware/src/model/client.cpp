#include "client.h"
#include <QHostAddress>
#include <QUuid>

Client::Client(QTcpSocket *socket, QObject *parent) : QObject(parent),
    m_client_socket(socket),
    m_uuid(QUuid::createUuid().toString(QUuid::WithoutBraces))
{
    assert(socket != nullptr);
    qDebug() << "Client Object created"
             << ip().append(":").append(port())
             << "UUID:" << this->m_uuid;
}

QString Client::ip() const
{
    return this->m_client_socket->peerAddress().toString();
}

quint16 Client::port() const
{
    return this->m_client_socket->peerPort();
}

const QString &Client::uuid() const
{
    return this->m_uuid;
}
