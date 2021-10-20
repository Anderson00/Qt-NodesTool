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

    Client *getClient(const QString &ip, int port);
    Client *getClient(const QString &uuid);

signals:
    void messageReceived(Client *client, QJsonObject message);
    void clientDisconnect(Client *client);
    void clientConnected(Client *client);

private slots:
    void processNewClient(QTcpSocket *client);
    void processNewMessage(QTcpSocket *client, QJsonObject message);

private:
    TCPServer *m_server;
    QList<Client*> m_clients;
};

#endif // NETWORKCONTROLLER_H
