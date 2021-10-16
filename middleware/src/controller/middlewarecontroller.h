#ifndef MIDDLEWARECONTROLLER_H
#define MIDDLEWARECONTROLLER_H

#include <QObject>
#include <src/controller/networkcontroller.h>

class MiddlewareController : public QObject
{
    Q_OBJECT
public:
    enum OperationMode{
        Lan, Network, Api
    };
    Q_ENUM(OperationMode)

    explicit MiddlewareController(OperationMode mode = Lan, QObject *parent = nullptr);

signals:

private:
    void init();

private:
    OperationMode m_mode;
    NetworkController *m_network_controller;
};

#endif // MIDDLEWARECONTROLLER_H
