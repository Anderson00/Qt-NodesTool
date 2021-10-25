#include "agenteobserver.h"
#include <QDebug>

AgenteObserver::AgenteObserver(const QString &keyFilter, QObject *parent) :
    QObject(parent),
    IObserver<QByteArray>(keyFilter)
{
    qDebug() << QString("AgenteObserver key: ").append(keyFilter);
}

void AgenteObserver::update(const QString &key, const QByteArray &newValue)
{
    emit cacheRowRemoved(newValue);
}

void AgenteObserver::rowRemoved(QString key)
{
    emit cacheRowRemoved(key);
}
