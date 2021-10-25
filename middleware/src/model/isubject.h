#ifndef ISUBJECT_H
#define ISUBJECT_H

#include "iobserver.h"

template <typename T>
class ISubject {
public:
    virtual ~ISubject(){};
    virtual void attach(IObserver<T> *observer) = 0;
    virtual void detach(IObserver<T> *observer) = 0;
    virtual void notify(const QString &key, const T &newValue) = 0;
};

#endif // ISUBJECT_H
