#include "client.h"
#include <QHostAddress>

Client::Client(QTcpSocket *socket, QObject *parent) : Agente(parent),
    m_client_socket(socket)
{
    assert(socket != nullptr);
    qDebug() << "Client Object created"
             << ip().append(":").append(port());

    QObject::connect(socket, &QTcpSocket::disconnected, this, &Client::disconnected);
}

Client::~Client()
{
    this->m_client_socket->close();
    delete m_client_socket;
}

QString Client::ip() const
{
    return this->m_client_socket->peerAddress().toString();
}

quint16 Client::port() const
{
    return this->m_client_socket->peerPort();
}

QString Client::toString() const
{
    return QString("Client{").append(ip().append(":").append(port()).append("}"));
}
