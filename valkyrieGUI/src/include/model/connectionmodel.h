#ifndef CONNECTIONMODEL_H
#define CONNECTIONMODEL_H

#include <QObject>
#include <QMetaMethod>
#include <QMetaObject>

class ConnectionModel : public QObject
{
    Q_OBJECT
public:
    explicit ConnectionModel(QObject *output, QMetaMethod signal, QObject *input, QMetaMethod slot, QObject *parent = nullptr);

    inline bool isValid(){
        return this->m_connection;
    }

    const QMetaObject::Connection &connection() const;
    void setConnection(const QMetaObject::Connection &newConnection);

    QObject *output() const;
    QObject *input() const;
    const QMetaMethod &signal() const;
    const QMetaMethod &slot() const;

signals:

private:
    QObject *m_output, *m_input;
    QMetaMethod m_signal, m_slot;
    QMetaObject::Connection m_connection;
};

#endif // CONNECTIONMODEL_H
