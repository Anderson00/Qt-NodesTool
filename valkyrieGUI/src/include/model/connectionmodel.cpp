#include "connectionmodel.h"
#include "behaviours/typecoercions.h"
#include <QDebug>

ConnectionModel::ConnectionModel(Behaviours *output, QMetaMethod signal, Behaviours *input, QMetaMethod slot, QObject *parent) :
    QObject(parent),
    m_output(output),
    m_input(input),
    m_signal(signal),
    m_slot(slot)
{
    qDebug() << "ConnectionModel" << output << input << signal.methodSignature() << slot.methodSignature();

    // ── Attempt exact-type Qt connection ────────────────────────────────────
    if (signal.methodType() == QMetaMethod::Slot && slot.methodType() == QMetaMethod::Signal) {
        m_connection = QObject::connect(m_input, m_slot, m_output, m_signal);
    } else {
        m_connection = QObject::connect(m_output, m_signal, m_input, m_slot);
    }

    // ── If exact connect failed, try a type-coercion relay ──────────────────
    if (!m_connection) {
        // Determine the actual signal source and slot target
        QObject*    senderObj;
        QMetaMethod senderSig;
        QObject*    receiverObj;
        QMetaMethod receiverSlot;

        if (signal.methodType() == QMetaMethod::Slot && slot.methodType() == QMetaMethod::Signal) {
            // Reversed wiring (input-side signal → output-side slot)
            senderObj    = m_input;
            senderSig    = m_slot;
            receiverObj  = m_output;
            receiverSlot = m_signal;
        } else {
            senderObj    = m_output;
            senderSig    = m_signal;
            receiverObj  = m_input;
            receiverSlot = m_slot;
        }

        const QByteArray srcParams = TypeCoercions::extractParams(senderSig.methodSignature());
        const QByteArray dstParams = TypeCoercions::extractParams(receiverSlot.methodSignature());

        m_coercionRelay = TypeCoercions::createRelay(srcParams, dstParams, this);
        if (m_coercionRelay) {
            // source signal → relay's rcv(srcParams) slot
            const QByteArray srcStr   = QByteArray("2") + senderSig.methodSignature();
            const QByteArray relayIn  = QByteArray("1rcv") + srcParams;
            m_relayConn1 = QObject::connect(senderObj,       srcStr.constData(),
                                             m_coercionRelay, relayIn.constData());

            // relay's fwd(dstParams) signal → target slot
            const QByteArray relayOut = QByteArray("2fwd") + dstParams;
            const QByteArray dstStr   = QByteArray("1") + receiverSlot.methodSignature();
            m_relayConn2 = QObject::connect(m_coercionRelay, relayOut.constData(),
                                             receiverObj,     dstStr.constData());

            if (!m_relayConn1 || !m_relayConn2) {
                qDebug() << "TypeCoercion relay wiring failed:"
                         << srcParams << "->" << dstParams;
                delete m_coercionRelay;
                m_coercionRelay = nullptr;
            } else {
                qDebug() << "TypeCoercion relay active:"
                         << srcParams << "->" << dstParams;
            }
        }
    }

    // Auto-destroy this model when either endpoint node is deleted
    QObject::connect(m_output, &QObject::destroyed, this, &QObject::deleteLater);
    QObject::connect(m_input,  &QObject::destroyed, this, &QObject::deleteLater);
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
