#ifndef AGENTE_H
#define AGENTE_H

#include <QObject>
#include <QHash>
#include <QString>

#include "agentecache.h"

class Agente : public QObject
{
    Q_OBJECT
public:
    explicit Agente(const QString& name, const QString& uuid = "", QObject *parent = nullptr);
    virtual ~Agente();

    Agente& operator=(const Agente& other) = delete;
    Agente& operator=(const Agente&& other) = delete;

    const QString &uuid()const;

    bool contains(const QString &key) const;
    const QString& get(const QString &key) const;
    const QString& keyFromValue(const QString &key) const;

    const QString& set(const QString &key, const QString &value);
    const QString& setReadOnly(const QString &key, const QString &value);

    virtual QString toString() const;

    virtual bool operator ==(const Agente& client){
        return true;
    }

    const QHash<QString, QString>& params() const;
    const QHash<QString, QString>& params(const QHash<QString, QString>& arg);

signals:

private:
    QHash<QString, QString> m_params;
    QString m_uuid;
    QString m_name;

    AgenteCache *m_cache;
};

#endif // AGENTE_H
