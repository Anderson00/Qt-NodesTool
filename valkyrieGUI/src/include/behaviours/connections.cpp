#include "connections.h"
#include <model/connectionmodel.h>
#include <QDebug>

Connections::Connections(QObject *obj, QMetaMethod metaMethod, QObject *parent) : QObject(parent),
    m_obj(obj),
    m_metaMethod(metaMethod)
{
     qDebug() << ">>>>> " <<this->metaMethod().methodSignature();
}

QString Connections::methodSignature()
{
    return this->m_metaMethod.methodSignature();
}

Connections::ConnMethodType Connections::methodType()
{
    return static_cast<ConnMethodType>(this->m_metaMethod.methodType());
}

QMetaMethod Connections::metaMethod()
{
    return this->m_metaMethod;
}

bool Connections::addConnection(QObject *output, QMetaMethod metaMethod)
{
    ConnectionModel *connectionModel = new ConnectionModel(this->m_obj, this->m_metaMethod, output, metaMethod);
    this->m_connections.push_back(connectionModel);
    return connectionModel->isValid();
}
