#ifndef LOCALDIRLSCOMMAND_H
#define LOCALDIRLSCOMMAND_H

#include <QObject>
#include <QJsonArray>
#include "command.h"

class LocalDirLSCommand : public Command
{
    Q_OBJECT
public:
    explicit LocalDirLSCommand(QObject *parent = nullptr);

public slots:
    void execute(QJsonArray params) override;
};

#endif // LOCALDIRLSCOMMAND_H
