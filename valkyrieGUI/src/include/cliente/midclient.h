#ifndef MIDCLIENT_H
#define MIDCLIENT_H

#include <QObject>
#include <QTcpSocket>
#include <QJsonObject>
#include <QJsonArray>

class MidClient : public QTcpSocket
{
    Q_OBJECT
public:
    explicit MidClient(QObject *parent = nullptr);

public slots:
    void sendCommand(const QString& cmdName, QJsonArray params);
    void retryConn(QString ip, qint16 port);

private slots:
    void processNewMessage();

signals:
    void resultCommand(QJsonObject message);

};

#endif // MIDCLIENT_H
