#include "client.h"
#include <QHostAddress>

Client::Client(QTcpSocket *socket, QObject *parent, const QString &name, const QString &uuid) :
    Agente((name.isEmpty())? socket->peerAddress().toString().append(":").append(QString::number(socket->peerPort())) : name,
           uuid,
           parent),
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

QTcpSocket *Client::socket()
{
    return this->m_client_socket;
}

QString Client::toString() const
{
    return QString("Client{").append(ip().append(":").append(port()).append("}"));
}

bool Client::operator ==(const Agente &agente)
{
    const Client &cli = static_cast<const Client&>(agente);
    if(cli.ip() == this->ip() && cli.port() == this->port() && cli.uuid() == this->uuid()){
        return true;
    }

    return false;
}
