#include "agente.h"
#include <QUuid>

Agente::Agente(QObject *parent) : QObject(parent),
    m_uuid(QUuid::createUuid().toString(QUuid::WithoutBraces))
{

}

Agente::~Agente()
{

}

const QString &Agente::uuid() const
{
    return this->m_uuid;
}

QString Agente::toString() const
{
    return QString("Agent{").append(m_uuid).append("}");
}

const QHash<QString, QString>& Agente::params() const
{
    return this->m_params;
}

const QHash<QString, QString>& Agente::params(const QHash<QString, QString> &arg)
{
    return (this->m_params = arg);
}
