#include "connections.h"

Connections::Connections(QMetaMethod metaMethod, QObject *parent) : QObject(parent),
    m_metaMethod(metaMethod)
{

}

QString Connections::methodSignature()
{
    return this->m_metaMethod.methodSignature();
}

Connections::ConnMethodType Connections::methodType()
{
    return static_cast<ConnMethodType>(this->m_metaMethod.methodType());
}
