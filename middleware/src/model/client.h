#ifndef CLIENTE_H
#define CLIENTE_H

#include <QObject>
#include <QTcpSocket>
#include <QHash>

class Client : public QObject
{
    Q_OBJECT
public:
    explicit Client(QTcpSocket *socket, QObject *parent = nullptr);

    QString ip()const;
    quint16 port()const;
    const QString &uuid()const;

    bool contains(const QString &key) const;
    const QString& get(const QString &key) const;
    const QString& keyFromValue(const QString &key) const;

    const QString& set(const QString &key, const QString &value);
    const QString& setReadOnly(const QString &key, const QString &value);

    inline bool operator ==(const Client& client){
        return (this->ip() == client.ip() && this->port() == client.port()) ||
               (this->uuid() == client.uuid());
    }

private:
    QTcpSocket *m_client_socket;
    QHash<QString, QString> m_params;
    QHash<QString, QString> m_params_read_only;
    QString m_uuid;
};

#endif // CLIENTE_H
