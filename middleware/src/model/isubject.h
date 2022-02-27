#ifndef ISUBJECT_H
#define ISUBJECT_H

#include "iobserver.h"

template <typename T>
class ISubject {
public:
    virtual ~ISubject(){};
    virtual void attach(IObserver<T> *observer) = 0;
    virtual void detach(IObserver<T> *observer) = 0;
    virtual void notifyUpdate(const QString &key, const T &newValue) = 0;
    virtual void notifyRemoved(const QString &key) = 0;
    virtual void notifyAdded(const QString &key, const T &newValue) = 0;
};

#endif // ISUBJECT_H
