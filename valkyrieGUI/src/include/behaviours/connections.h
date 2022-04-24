#ifndef CONNECTIONS_H
#define CONNECTIONS_H

#include <QObject>
#include <QList>
#include <QMetaMethod>
#include <model/connectionmodel.h>

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

    explicit Connections(QObject *obj, QMetaMethod metaMethod, QObject *parent = nullptr);

    QString methodSignature();
    ConnMethodType methodType();
    QMetaMethod metaMethod();

public slots:
    bool addConnection(QObject *output, QMetaMethod metaMethod);

signals:


private:
    QObject *m_obj;
    QMetaMethod m_metaMethod;
    QList<ConnectionModel*> m_connections;
};

#endif // CONNECTIONS_H
