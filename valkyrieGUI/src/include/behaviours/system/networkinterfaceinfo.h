#ifndef NETWORKINTERFACEINFO_H
#define NETWORKINTERFACEINFO_H

#include <QObject>
#include <QJsonObject>
#include <QNetworkInterface>
#include <QNetworkAddressEntry>
#include <QAbstractSocket>
#include <behaviours/behaviours.h>

class NetworkInterfaceInfo : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int interfaceCount READ interfaceCount NOTIFY interfaceCountChanged)

public:
    explicit NetworkInterfaceInfo(QObject *parent = nullptr);

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    int interfaceCount() const;

public slots:
    void refresh();

signals:
    // Node output
    void interfacesFetched(QVariantList interfaces);

    // Internal QML-only signals
    void internalInterfacesFetched(QVariantList interfaces);

    // Property notifiers
    void interfaceCountChanged();

private:
    int m_interfaceCount = 0;
};

#endif // NETWORKINTERFACEINFO_H
