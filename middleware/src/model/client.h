#ifndef CLIENTE_H
#define CLIENTE_H

#include <QObject>
#include <QTcpSocket>
#include <QHash>

#include "agente.h"

class Client : public Agente
{
    Q_OBJECT
public:
    explicit Client(QTcpSocket *socket, QObject *parent = nullptr);
    ~Client();

    QString ip()const;
    quint16 port()const;

    QString toString() const override;

    inline bool operator ==(const Agente& agente) override {
        const Client& client = static_cast<const Client&>(agente);

        return (this->ip() == client.ip() && this->port() == client.port()) ||
               (this->uuid() == client.uuid());
    }

    inline bool operator ==(const Client* client) {
        return (this->ip() == client->ip() && this->port() == client->port()) ||
               (this->uuid() == client->uuid());
    }

    Client& operator=(const Client& other) = delete;
    Client& operator=(const Client&& other) = delete;

signals:
    void disconnected();

private:
    QTcpSocket *m_client_socket;
};

#endif // CLIENTE_H
