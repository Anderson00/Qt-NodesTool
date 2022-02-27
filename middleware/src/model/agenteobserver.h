#ifndef AGENTEOBSERVER_H
#define AGENTEOBSERVER_H

#include <QObject>

#include "iobserver.h"

class AgenteObserver : public QObject, public IObserver<QByteArray>
{
    Q_OBJECT
public:
    explicit AgenteObserver(const QString &keyFilter, QObject *parent = nullptr);

signals:
    void cacheRowUpdated(const QByteArray &newValue);
    void cacheRowRemoved(QString key);
    void cacheRowAddeded(QString key);

private:
    void update(const QString& key, const QByteArray &newValue) override;
    void rowRemoved(QString key) override;
    void rowAddeded(QString key, const QByteArray &newValue) override;

};

#endif // AGENTEOBSERVER_H
