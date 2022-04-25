#include "connections.h"
#include <model/connectionmodel.h>
#include <QDebug>

Connections::Connections(QObject *obj, QMetaMethod metaMethod, QObject *parent) : QObject(parent),
    m_obj(obj),
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

QMetaMethod Connections::metaMethod()
{
    return this->m_metaMethod;
}

ConnectionModel* Connections::addConnection(QObject *output, QMetaMethod metaMethod)
{
    ConnectionModel *connectionModel = new ConnectionModel(this->m_obj, this->m_metaMethod, output, metaMethod);    
    if(!connectionModel->isValid()){
        delete connectionModel;
        connectionModel = nullptr;
    }else{
        this->m_connections.push_back(connectionModel);
        QObject::connect(connectionModel, &QObject::destroyed, [this, connectionModel](){
            this->m_connections.removeOne(connectionModel);
            qDebug() << "removed" << connectionModel;
        });
    }
    return connectionModel;
}

ConnectionModel *Connections::addConnection(ConnectionModel *conn)
{
    this->m_connections.push_back(conn);
    QObject::connect(conn, &QObject::destroyed, [this, conn](){
        this->m_connections.removeOne(conn);
    });
    return conn;
}
