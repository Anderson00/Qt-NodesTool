#include "command.h"

Command::Command(const QString& commandName, QObject *parent) :
    m_cmdName(commandName)
{

}

const QString &Command::cmdName() const
{
    return m_cmdName;
}
