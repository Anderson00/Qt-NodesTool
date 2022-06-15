#ifndef CONNECTIONS_H
#define CONNECTIONS_H

#include <QObject>
#include <QList>
#include <QMetaMethod>
#include <model/connectionmodel.h>
#include <behaviours/behaviours.h>

class Behaviours;
class ConnectionModel;

class Connections : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString methodSignature READ methodSignature CONSTANT)
    Q_PROPERTY(ConnMethodType methodType READ methodType CONSTANT)
public:
    enum ConnMethodType {
        Method = 0, Signal, Slot, Contructor
    };
    Q_ENUM(ConnMethodType)

    explicit Connections(Behaviours *obj, QMetaMethod metaMethod, QObject *parent = nullptr);

    QString methodSignature();
    ConnMethodType methodType();
    QMetaMethod metaMethod();

public slots:
    ConnectionModel *addConnection(Behaviours *output, QMetaMethod metaMethod);
    ConnectionModel *addConnection(ConnectionModel* conn);

signals:


private:
    Behaviours *m_obj;
    QMetaMethod m_metaMethod;
    QList<ConnectionModel*> m_connections;
};

#endif // CONNECTIONS_H
