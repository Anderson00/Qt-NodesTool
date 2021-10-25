#ifndef AGENTECACHE_H
#define AGENTECACHE_H

#include <QObject>
#include <QByteArray>
#include <QList>
#include <QString>
#include "cache.h"
#include "agenteobserver.h"

class AgenteCache : public QObject
{
    Q_OBJECT
public:
    explicit AgenteCache(QObject *parent = nullptr);
    ~AgenteCache();

    bool registerKeyHook(const QString &key);
    bool unRegisterKeyHook(const QString &key);
    quint32 memoryCost();

signals:
    void addeded(QString key, QByteArray value);
    void removed(QString key, QByteArray value);
    void updated(QString key, QByteArray oldValue, QByteArray newValue);

private:
    Cache<QByteArray> *m_cache_general;
    Cache<QByteArray> *m_cache_reserved;

    QList<AgenteObserver*> m_observers;
};

#endif // AGENTECACHE_H
