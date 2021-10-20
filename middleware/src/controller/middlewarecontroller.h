#ifndef MIDDLEWARECONTROLLER_H
#define MIDDLEWARECONTROLLER_H

#include <QObject>
#include <src/model/agente.h>
#include <src/controller/networkcontroller.h>

class MiddlewareController : public QObject
{
    Q_OBJECT
public:
    enum OperationMode{
        Lan, Network, Api, RestApi
    };
    Q_ENUM(OperationMode)

    explicit MiddlewareController(OperationMode mode = Lan, QObject *parent = nullptr);    

signals:

private slots:
    void processAgentConnection(Agente *source);
    void processRequest(Agente *source, QJsonObject request);

private:
    void init();

    OperationMode m_mode;
    NetworkController *m_network_controller;
};

#endif // MIDDLEWARECONTROLLER_H
