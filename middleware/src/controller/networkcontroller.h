#ifndef NETWORKCONTROLLER_H
#define NETWORKCONTROLLER_H

#include <QObject>
#include <QList>
#include <src/network/tcpserver.h>
#include <src/model/client.h>

class NetworkController : public QObject
{
    Q_OBJECT
public:
    explicit NetworkController(QObject *parent = nullptr);
    ~NetworkController();

    const Client *getClient(const QString &ip, int port);
    const Client *getClient(const QString &uuid);

signals:
    void messageReceived(const Client *client, QJsonObject message);
    void clientDisconnect(const Client *client);
    void clientConnected(const Client *client);

private slots:
    void processNewClient(QTcpSocket *client);
    void processNewMessage(QTcpSocket *client, QJsonObject message);

private:
    TCPServer *m_server;
    QList<Client*> m_clients;
};

#endif // NETWORKCONTROLLER_H
