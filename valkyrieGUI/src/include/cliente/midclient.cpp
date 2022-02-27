#include "midclient.h"
#include <QJsonObject>
#include <QJsonDocument>

MidClient::MidClient(QObject *parent) : QTcpSocket(parent)
{
    QObject::connect(this, &QTcpSocket::readyRead, this, &MidClient::processNewMessage);
}

void MidClient::sendCommand(const QString &cmdName, QJsonArray params)
{

    if(this->state() == ConnectedState){
        QJsonObject payload({
                                {"cmd", cmdName},
                                {"params", params}
                            });
        this->write(QJsonDocument(payload).toJson(QJsonDocument::Compact));
    }
}

void MidClient::retryConn(QString ip, qint16 port)
{
    this->connectToHost(ip, port);
}

void MidClient::processNewMessage()
{
    QByteArray byteArray =  this->readAll();
    if(byteArray.size() > 0){
        QJsonDocument doc = QJsonDocument::fromJson(byteArray);
        if(doc.isObject()){
            QJsonObject obj = doc.object();
            if(obj.contains("cmd")){
                emit resultCommand(obj);
            }
        }else{

        }
    }
}
