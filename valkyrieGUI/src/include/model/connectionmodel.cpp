#include "connectionmodel.h"
#include <QDebug>

ConnectionModel::ConnectionModel(QObject *output, QMetaMethod signal, QObject *input, QMetaMethod slot, QObject *parent) :
    QObject(parent),
    m_output(output),
    m_input(input),
    m_signal(signal),
    m_slot(slot)
{
    qDebug() << "ConnectionModel" << output << input << signal.methodSignature() << slot.methodSignature();
    this->m_connection = QObject::connect(m_output, m_signal, m_input, m_slot);

}

QObject *ConnectionModel::output() const
{
    return m_output;
}

QObject *ConnectionModel::input() const
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
