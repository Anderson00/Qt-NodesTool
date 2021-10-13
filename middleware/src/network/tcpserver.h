#ifndef TCPSERVER_H
#define TCPSERVER_H

#include <QObject>
#include <QList>
#include <QTcpServer>
#include <QTcpSocket>
#include <QJsonObject>

class TCPServer : public QObject
{
    Q_OBJECT
public:
    explicit TCPServer(QObject *parent = nullptr);
    ~TCPServer();

signals:
    void newClient(QTcpSocket *client);
    void newMessage(QTcpSocket *client, QJsonObject message);

private slots:
    void processTCPMessage(QTcpSocket *client, const QByteArray& bytes);

private:
    QTcpServer *m_server;
    QList<QTcpSocket*> m_clients;
};

#endif // TCPSERVER_H
