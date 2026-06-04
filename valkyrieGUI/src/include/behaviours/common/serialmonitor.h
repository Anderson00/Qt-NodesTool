#ifndef SERIALMONITOR_H
#define SERIALMONITOR_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class SerialMonitor : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString port      READ port      NOTIFY portChanged)
    Q_PROPERTY(bool    connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(int     baud      READ baud      NOTIFY baudChanged)

public:
    explicit SerialMonitor(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString port()      const;
    bool    connected() const;
    int     baud()      const;

public slots:
    void sendData(const QString& data);
    void setBaud(int baud);
    void setPort(const QString& port);
    void connectPort();
    void disconnectPort();
    void clear();

signals:
    void internalRxData(const QString& data);
    void internalTxData(const QString& data);
    void internalClear();

    void outputReceived(QString data);
    void portChanged();
    void connectedChanged();
    void baudChanged();

private:
    QString m_port;
    bool    m_connected = false;
    int     m_baud      = 9600;
};

#endif // SERIALMONITOR_H
