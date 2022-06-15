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
