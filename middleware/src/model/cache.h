#ifndef CACHE_H
#define CACHE_H

#include <QObject>
#include <QString>
#include <QHash>
#include <QList>
#include <QMutex>

#include "isubject.h"
#include "iobserver.h"

template <typename T>
class Cache : public ISubject<T>
{
public:
    Cache();

    Cache& operator=(const Cache& other) = delete;
    Cache& operator=(const Cache&& other) = delete;

    bool contains(const QString &key) const;
    QString keyFromValue(const T &value) const;

    const T& get(const QString &key) const;
    const T& set(const QString &key, const T &value);

    int size();

    //ISubject impls
    void attach(IObserver<T> *observer) override;
    void detach(IObserver<T> *observer) override;

private:
    //ISubject impl
    void notify(const QString &key, const T &newValue) override;

    QHash<QString, T> m_general_data;
    QList<IObserver<T>*> m_observers;
};

template<typename T>
Cache<T>::Cache()
{

}

template<typename T>
int Cache<T>::size()
{
    return this->m_general_data.count();
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
void Cache<T>::notify(const QString &key, const T &newValue)
{
    for(IObserver<T> *observer : qAsConst(this->m_observers)){
        if(observer->key() == key){
            observer->update(key, newValue);
        }
    }
}



#endif // CACHE_H
