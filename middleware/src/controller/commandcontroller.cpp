#include "commandcontroller.h"
#include <src/command/localdirlscommand.h>
#include <QJsonArray>

CommandController::CommandController(QObject *parent) : QObject(parent)
{
    init();
}

bool CommandController::executeCmd(Agente *agente, const QString &cmdName, QJsonArray params)
{
    if(this->m_commands.contains(cmdName)){
        Command *cmd = this->m_commands[cmdName];

        QObject::connect(cmd, &Command::result, [this, agente, cmd](QVariant result){
            QJsonArray array;
            if(result.canConvert<QString>()){
                array.push_back(result.toString());
            }else if(result.canConvert<QStringList>()){
                QStringList listOfResults = result.toStringList();

                for(QString& str : listOfResults){
                    array.push_back(str);
                }
            }

            QJsonObject message ({
                {"cmd", cmd->cmdName()},
                {"result", array}
            });
            emit resultReady(agente, message);
        });

        cmd->execute(params);

        return true;
    }

    return false;
}

bool CommandController::executeCmd(const QString &cmdName, QJsonArray params)
{
    if(this->m_commands.contains(cmdName)){



        return true;
    }

    return false;
}

void CommandController::init()
{
    LocalDirLSCommand *lsCommand = new LocalDirLSCommand(nullptr);

    this->m_commands.insert(lsCommand->cmdName(), lsCommand);
    // TODO: add commands
}
