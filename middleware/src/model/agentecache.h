#ifndef AGENTECACHE_H
#define AGENTECACHE_H

#include <QObject>
#include <QByteArray>
#include <QList>
#include <QString>
#include "cache.h"
#include "agenteobserver.h"

template <typename T>
class Cache;

class AgenteCache : public QObject
{
    Q_OBJECT
public:
    explicit AgenteCache(QObject *parent = nullptr);
    ~AgenteCache();

    bool registerKeyHook(const QString &key);
    bool unRegisterKeyHook(const QString &key);

    bool registerKeyHookReserved(const QString &key);
    bool unRegisterKeyHookReserved(const QString &key);
    quint32 memoryCost();

signals:
    void addeded(QString key, QByteArray value);
    void removed(QString key, QByteArray value);
    void updated(QString key, QByteArray oldValue, QByteArray newValue);

private:
    void removeAgenteObserver(AgenteObserver *observer);

    Cache<QByteArray> *m_cache_general;
    Cache<QByteArray> *m_cache_reserved;

    QList<AgenteObserver*> m_observers;
};

#endif // AGENTECACHE_H
