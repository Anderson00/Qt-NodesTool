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
    Client(QTcpSocket *socket, QObject *parent = nullptr, const QString &name = "", const QString &uuid = "");
    ~Client();

    QString ip()const;
    quint16 port()const;
    QTcpSocket *socket();

    QString toString() const override;

    bool operator ==(const Agente& agente) override;

    Client& operator=(const Client& other) = delete;
    Client& operator=(const Client&& other) = delete;

signals:
    void disconnected();

private:
    QTcpSocket *m_client_socket;
};

#endif // CLIENTE_H
