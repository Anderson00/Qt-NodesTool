#include "connectionmodel.h"
#include <QDebug>

ConnectionModel::ConnectionModel(Behaviours *output, QMetaMethod signal, Behaviours *input, QMetaMethod slot, QObject *parent) :
    QObject(parent),
    m_output(output),
    m_input(input),
    m_signal(signal),
    m_slot(slot)
{
    qDebug() << "ConnectionModel" << output << input << signal.methodSignature() << slot.methodSignature();

    if(signal.methodType() == QMetaMethod::Slot && slot.methodType() == QMetaMethod::Signal){
        this->m_connection = QObject::connect(m_input, m_slot, m_output, m_signal);
    }else{
        this->m_connection = QObject::connect(m_output, m_signal, m_input, m_slot);
    }

    // Auto-destroy this connection model if either endpoint node is deleted
    QObject::connect(m_output, &QObject::destroyed, this, &QObject::deleteLater);
    QObject::connect(m_input, &QObject::destroyed, this, &QObject::deleteLater);

}

Behaviours *ConnectionModel::output() const
{
    return m_output;
}

Behaviours *ConnectionModel::input() const
{
    return m_input;
}

const QMetaMethod &ConnectionModel::signal() const
{
    return m_signal;
}

const QMetaMethod &ConnectionModel::slot() const
{
    return m_slot;
}

const QMetaObject::Connection &ConnectionModel::connection() const
{
    return m_connection;
}

void ConnectionModel::setConnection(const QMetaObject::Connection &newConnection)
{
    m_connection = newConnection;
}
