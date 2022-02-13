#ifndef MIDDLEWARECONTROLLER_H
#define MIDDLEWARECONTROLLER_H

#include <QObject>
#include <src/model/agente.h>
#include <src/controller/networkcontroller.h>
#include <src/controller/commandcontroller.h>

class MiddlewareController : public QObject
{
    Q_OBJECT
public:
    enum OperationMode{
        Lan, Network, Api, RestApi, Unknow
    };
    Q_ENUM(OperationMode)

    explicit MiddlewareController(OperationMode mode = Lan, const QString &filesPath = "", QObject *parent = nullptr);

    QStringList filesList() const;

signals:
    void quit(int exitCode = 0);

private slots:
    void executeCommand(Agente *client, QJsonObject message);
    void processAgentConnection(Agente *source);
    void processRequest(Agente *source, QJsonObject request);

private:
    void init();

    OperationMode m_mode;
    QString m_files_path;
    QList<Agente*> m_agentes;
    NetworkController *m_network_controller;
    CommandController *m_command_controller;
};

#endif // MIDDLEWARECONTROLLER_H
