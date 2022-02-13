#ifndef COMMAND_H
#define COMMAND_H

#include <QObject>
#include <QVariant>
#include <QJsonArray>
#include <functional>

class Command : public QObject
{
    Q_OBJECT
public:
    explicit Command(const QString& commandName, QObject *parent = nullptr);

    const QString &cmdName() const;

public slots:
    virtual void execute(QJsonArray params) = 0;

signals:
    void result(QVariant);

public:
    QString m_cmdName;
};

#endif // COMMAND_H
