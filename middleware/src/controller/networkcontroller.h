#ifndef NETWORKCONTROLLER_H
#define NETWORKCONTROLLER_H

#include <QObject>
#include <src/network/tcpserver.h>

class NetworkController : public QObject
{
    Q_OBJECT
public:
    explicit NetworkController(QObject *parent = nullptr);

signals:
    //messageReceived(QJSON)

private:
    TCPServer *m_server;
};

#endif // NETWORKCONTROLLER_H
