#ifndef NETWORKCONTROLLER_H
#define NETWORKCONTROLLER_H

#include <QObject>
#include <QList>
#include <src/network/tcpserver.h>
#include <src/model/client.h>

class Client;

class NetworkController : public QObject
{
    Q_OBJECT
public:
    explicit NetworkController(QObject *parent = nullptr);
    ~NetworkController();

    Client *getClient(const QString &ip, int port);
    Client *getClient(const QString &uuid);

signals:
    void messageReceived(Client *client, QJsonObject message);
    void clientDisconnect(Client *client);
    void clientConnected(Client *client);
    void clientReconnection(Client *client);

public slots:
    void sendMessage(Client *client, QJsonObject message);

private slots:
    void processNewClient(QTcpSocket *client);
    void processClientReconnection(Client *client);
    void processClientDisconnection(Client *client);
    void processNewMessage(QTcpSocket *client, QJsonObject message);

private:
    Client *getClientDisconnected(const Client *client);

    TCPServer *m_server;
    QList<Client*> m_clients;
    QList<Client*> m_clientsDisconected;
    QList<QTimer*> m_reconnectionTimeout;
};

#endif // NETWORKCONTROLLER_H
