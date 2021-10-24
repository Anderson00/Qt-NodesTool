#ifndef CACHE_H
#define CACHE_H

#include <QObject>
#include <QString>
#include <QHash>
#include <QMutex>

template <typename  T>
class Cache
{
public:
    Cache();

    Cache& operator=(const Cache& other) = delete;
    Cache& operator=(const Cache&& other) = delete;

    bool contains(const QString &key) const;
    QString keyFromValue(const T &value) const;

    T get(const QString &key) const;
    T set(const QString &key, const T &value);

    int size();

private:
    QHash<QString, T> m_general_data;
};

#endif // CACHE_H
