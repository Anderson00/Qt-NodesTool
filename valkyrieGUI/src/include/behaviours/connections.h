#ifndef CONNECTIONS_H
#define CONNECTIONS_H

#include <QObject>
#include <QMetaMethod>

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

    explicit Connections(QMetaMethod metaMethod, QObject *parent = nullptr);

    QString methodSignature();
    ConnMethodType methodType();

public slots:
    //bool addConnection();

signals:


private:
    QMetaMethod m_metaMethod;
};

#endif // CONNECTIONS_H
