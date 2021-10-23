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

    bool isListening() const;
    void close();

signals:
    void newClient(QTcpSocket *client);
    void newMessage(QTcpSocket *client, QJsonObject message);

public slots:
    void sendMessage(QTcpSocket *destination, QJsonObject message);
    void sendToAll(QJsonObject message);

private slots:
    void processTCPMessage(QTcpSocket *client, const QByteArray& bytes);
    void sendToAll(QList<QTcpSocket*> clients, QJsonObject message);

private:
    QTcpServer *m_server;
    QList<QTcpSocket*> m_clients;
};

#endif // TCPSERVER_H
