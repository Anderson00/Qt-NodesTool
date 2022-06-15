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

    inline bool isValid(){
        return this->m_connection;
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
    QMetaObject::Connection m_connection;
};

#endif // CONNECTIONMODEL_H
