#ifndef CACHE_H
#define CACHE_H

#include <QObject>
#include <QString>
#include <QHash>
#include <QList>
#include <QMutex>

#include "agentecache.h"
#include "isubject.h"
#include "iobserver.h"

class AgenteCache;

template <typename T>
class Cache : public ISubject<T>
{
    friend class AgenteCache;
public:
    Cache();

    Cache& operator=(const Cache& other) = delete;
    Cache& operator=(const Cache&& other) = delete;

    bool contains(const QString &key) const;
    QString keyFromValue(const T &value) const;

    const T &get(const QString &key);
    const T get(const QString &key) const;
    const T &set(const QString &key, const T &value);
    bool remove(const QString &key);

    int rowCount();

    //ISubject impls
    void attach(IObserver<T> *observer) override;
    void detach(IObserver<T> *observer) override;

private:
    //ISubject impl
    void notifyUpdate(const QString &key, const T &newValue) override;
    void notifyRemoved(const QString &key) override;
    void notifyAdded(const QString &key, const T &newValue) override;

    QHash<QString, T> m_general_data;
    QList<IObserver<T>*> m_observers;
};

template<typename T>
Cache<T>::Cache()
{

}

template<typename T>
bool Cache<T>::contains(const QString &key) const
{
    return this->m_general_data.contains(key);
}

template<typename T>
const T Cache<T>::get(const QString &key) const
{
    return m_general_data[key];
}

template<typename T>
const T &Cache<T>::get(const QString &key)
{
    return static_cast<T&>(m_general_data[key]);
}

template<typename T>
const T &Cache<T>::set(const QString &key, const T &value)
{
    bool isAddition = !this->m_general_data.contains(key);

    this->m_general_data[key] = value;


    if(isAddition){
        this->notifyAdded(key, this->m_general_data[key]);
    }else{
        this->notifyUpdate(key, this->m_general_data[key]);
    }

    return this->m_general_data[key];
}

template<typename T>
bool Cache<T>::remove(const QString &key)
{
    if(!m_general_data.contains(key)){
        return false;
    }

    m_general_data.remove(key);
    this->notifyRemoved(key);

    return true;
}

template<typename T>
int Cache<T>::rowCount()
{
    return this->m_general_data.size();
}

template<typename T>
void Cache<T>::attach(IObserver<T> *observer)
{
    this->m_observers.push_back(observer);
}

template<typename T>
void Cache<T>::detach(IObserver<T> *observer)
{
    this->m_observers.removeOne(observer);
}

template<typename T>
void Cache<T>::notifyUpdate(const QString &key, const T &newValue)
{
    for(IObserver<T> *observer : qAsConst(this->m_observers)){
        if(observer->key() == key){
            observer->update(key, newValue);
        }
    }
}

template<typename T>
void Cache<T>::notifyRemoved(const QString &key)
{
    for(IObserver<T> *observer : qAsConst(this->m_observers)){
        if(observer->key() == key){
            observer->rowRemoved(key);
        }
    }
}

template<typename T>
void Cache<T>::notifyAdded(const QString &key, const T &newValue)
{
    for(IObserver<T> *observer : qAsConst(this->m_observers)){
        if(observer->key() == key){
            observer->rowAddeded(key, newValue);
        }
    }
}



#endif // CACHE_H
