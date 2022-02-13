#ifndef COMMANDCONTROLLER_H
#define COMMANDCONTROLLER_H

#include <QObject>
#include <QVariant>
#include <QJsonObject>
#include <QHash>
#include <src/command/command.h>
#include <src/model/agente.h>

class CommandController : public QObject
{
    Q_OBJECT
public:
    explicit CommandController(QObject *parent = nullptr);

public slots:
    bool executeCmd(Agente* agente, const QString& cmdName, QJsonArray params);
    bool executeCmd(const QString& cmdName, QJsonArray params);

signals:
    void resultReady(Agente* agente, QJsonObject result);
    void resultError(Agente* agente, QJsonObject result);

private:
    void init();

    QHash<QString, Command*> m_commands;
};

#endif // COMMANDCONTROLLER_H
