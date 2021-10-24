#ifndef AGENTECACHE_H
#define AGENTECACHE_H

#include <QObject>
#include <QByteArray>
#include <QString>
#include "cache.h"

class AgenteCache : public QObject
{
    Q_OBJECT
public:
    explicit AgenteCache(QObject *parent = nullptr);

    bool registerKeyHook(const QString &key);
    quint32 memoryCoast();

signals:
    void addeded(QString key, QByteArray value);
    void removed(QString key, QByteArray value);
    void updated(QString key, QByteArray oldValue, QByteArray newValue);

private:
    Cache<QByteArray> *m_cache_general;
    Cache<QByteArray> *m_cache_reserved;
};

#endif // AGENTECACHE_H
