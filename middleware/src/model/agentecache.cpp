#include "agentecache.h"
#include "cache.h"

AgenteCache::AgenteCache(QObject *parent) : QObject(parent)
{
    this->m_cache_general = new Cache<QByteArray>();
    //this->m_cache_reserved = new Cache<QByteArray*>();
}

AgenteCache::~AgenteCache()
{
    delete this->m_cache_general;
    delete this->m_cache_reserved;

    for(AgenteObserver *observer : qAsConst(this->m_observers)){
        delete observer;
    }
}

bool AgenteCache::registerKeyHook(const QString &key)
{
    AgenteObserver *observer = new AgenteObserver(key, this);
    this->m_observers.push_back(observer);
    this->m_cache_general->attach(observer);
    // TODO: failure case, return false
    return true;
}

bool AgenteCache::unRegisterKeyHook(const QString &key)
{
    for(AgenteObserver *observer : qAsConst(this->m_observers)){
        if(observer->key() == key){
            this->m_cache_general->detach(observer);
            delete observer;
            this->m_observers.removeOne(observer);
            return true;
        }
    }

    return false;
}

bool AgenteCache::registerKeyHookReserved(const QString &key)
{
    AgenteObserver *observer = new AgenteObserver(key, this);
    this->m_observers.push_back(observer);
    this->m_cache_reserved->attach(observer);
    // TODO: failure case, return false
    return true;
}

bool AgenteCache::unRegisterKeyHookReserved(const QString &key)
{
    for(AgenteObserver *observer : qAsConst(this->m_observers)){
        if(observer->key() == key){
            this->m_cache_general->detach(observer);
            delete observer;
            this->m_observers.removeOne(observer);
            return true;
        }
    }

    return false;
}

quint32 AgenteCache::memoryCost()
{
    quint64 sizeInBytes = 0;

    for(const QByteArray &array : qAsConst(this->m_cache_general->m_general_data)){
        sizeInBytes += array.size();
    }

    for(const QByteArray &array : qAsConst(this->m_cache_reserved->m_general_data)){
        sizeInBytes += array.size();
    }

    return sizeInBytes;
}

void AgenteCache::removeAgenteObserver(AgenteObserver *observer)
{
    this->m_observers.removeAll(observer);
}
