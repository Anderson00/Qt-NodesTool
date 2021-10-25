#ifndef IOBSERVER_H
#define IOBSERVER_H

#include <QString>

template <typename T>
class IObserver {
public:
    IObserver(const QString& key) : m_key(key){

    }
    virtual ~IObserver(){};
    virtual void update(const QString& key, const T &newValue) = 0;
    virtual void rowRemoved(QString key) = 0;

    inline const QString &key(){
        return this->m_key;
    }

private:
    QString m_key;
};

#endif // IOBSERVER_H
