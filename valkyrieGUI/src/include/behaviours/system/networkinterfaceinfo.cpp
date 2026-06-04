#include "networkinterfaceinfo.h"
#include "behaviours/behaviourregistry.h"
#include <QTimer>

REGISTER_BEHAVIOUR(NetworkInterfaceInfo, "Network Interfaces", "List all network interfaces with IP and MAC addresses", "system", 1, 1)

NetworkInterfaceInfo::NetworkInterfaceInfo(QObject *parent) : Behaviours(parent)
{
    setWidth(320);
    setHeight(280);
    setContentHeight(280);
    setQmlBodyUrl("qrc:/behaviours/system/NetworkInterfaceInfo.qml");
    addInputOutputExclusion(QList<QString>({
        "internalInterfacesFetched(QVariantList)",
        "interfaceCountChanged()"
    }));

    // Defer the initial refresh until after construction so that any signal
    // connections made by callers (e.g. QML bindings) are already in place
    // when the first interfacesFetched() signal fires.
    QTimer::singleShot(0, this, &NetworkInterfaceInfo::refresh);
}

void NetworkInterfaceInfo::onPinsReady()
{
    // inputs
    setPinTypeForSignature("refresh()", Connections::FlowType);
    // outputs
    setPinTypeForSignature("interfacesFetched(QVariantList)", Connections::ArrayType);
}

QMap<QString, QVariant> NetworkInterfaceInfo::loadInfos() { return NetworkInterfaceInfo::static_infos(); }

QMap<QString, QVariant> NetworkInterfaceInfo::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",           "NetworkInterfaceInfo"},
        {"type",           Behaviours::Type::CPP},
        {"className",      "NetworkInterfaceInfo"},
        {"desc",           "List all network interfaces with IP and MAC addresses"},
        {"inputs_count",   "1"},
        {"outputs_count",  "1"}
    });
}

int NetworkInterfaceInfo::interfaceCount() const { return m_interfaceCount; }

void NetworkInterfaceInfo::refresh()
{
    QVariantList result;

    const QList<QNetworkInterface> ifaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface &iface : ifaces) {
        if (!iface.isValid())
            continue;

        QString ip4, ip6;
        const QList<QNetworkAddressEntry> entries = iface.addressEntries();
        for (const QNetworkAddressEntry &entry : entries) {
            if (entry.ip().protocol() == QAbstractSocket::IPv4Protocol && ip4.isEmpty()) {
                ip4 = entry.ip().toString();
            } else if (entry.ip().protocol() == QAbstractSocket::IPv6Protocol && ip6.isEmpty()) {
                ip6 = entry.ip().toString();
            }
        }

        QNetworkInterface::InterfaceFlags flags = iface.flags();
        bool isUp       = flags.testFlag(QNetworkInterface::IsUp);
        bool isLoopback = flags.testFlag(QNetworkInterface::IsLoopBack);

        QVariantMap entry;
        entry["name"]       = iface.name();
        entry["mac"]        = iface.hardwareAddress();
        entry["ip4"]        = ip4;
        entry["ip6"]        = ip6;
        entry["isUp"]       = isUp;
        entry["isLoopback"] = isLoopback;

        result.append(entry);
    }

    m_interfaceCount = result.size();
    emit interfaceCountChanged();
    emit interfacesFetched(result);
    emit internalInterfacesFetched(result);
}
