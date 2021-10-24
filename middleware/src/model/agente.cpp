#include "agente.h"
#include <QUuid>
#include <QDebug>

Agente::Agente(const QString& name, const QString& uuid, QObject *parent) : QObject(parent),
    m_name(name)
{
    QUuid uuidCheck(uuid);
    if(uuidCheck.variant() == QUuid::VarUnknown || uuid.isNull()){
        this->m_uuid = QUuid::createUuid().toString(QUuid::WithoutBraces);
    }else{
        this->m_uuid = uuidCheck.toString(QUuid::WithoutBraces);
    }

    qDebug() << "New" << Agente::toString();
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
    return QString("Agent{").append(this->m_name).append(":").append(m_uuid).append("}");
}

const QHash<QString, QString>& Agente::params() const
{
    return this->m_params;
}

const QHash<QString, QString>& Agente::params(const QHash<QString, QString> &arg)
{
    return (this->m_params = arg);
}
