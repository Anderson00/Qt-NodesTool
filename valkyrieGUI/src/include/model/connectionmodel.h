#ifndef CONNECTIONMODEL_H
#define CONNECTIONMODEL_H

#include <QObject>
#include <QMetaMethod>
#include <QMetaObject>
#include <behaviours/behaviours.h>

class Behaviours;

class ConnectionModel : public QObject
{
    Q_OBJECT
public:
    explicit ConnectionModel(Behaviours *output, QMetaMethod signal, Behaviours *input, QMetaMethod slot, QObject *parent = nullptr);

    inline bool isValid() {
        // Valid if direct connection succeeded OR coercion relay is fully wired
        return m_connection ||
               (m_coercionRelay != nullptr && m_relayConn1 && m_relayConn2);
    }

    const QMetaObject::Connection &connection() const;
    void setConnection(const QMetaObject::Connection &newConnection);

    Behaviours *output() const;
    Behaviours *input() const;
    const QMetaMethod &signal() const;
    const QMetaMethod &slot() const;

signals:

private:
    Behaviours *m_output, *m_input;
    QMetaMethod m_signal, m_slot;

    // Direct Qt connection (non-null when types matched exactly)
    QMetaObject::Connection m_connection;

    // Coercion relay: non-null when a type-conversion bridge is in use.
    // Parented to this ConnectionModel → auto-deleted when the model is destroyed.
    QObject*                m_coercionRelay = nullptr;
    QMetaObject::Connection m_relayConn1;   // source signal  → relay rcv slot
    QMetaObject::Connection m_relayConn2;   // relay fwd signal → target slot
};

#endif // CONNECTIONMODEL_H
