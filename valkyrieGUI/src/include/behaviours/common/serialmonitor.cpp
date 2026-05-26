#include "serialmonitor.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(SerialMonitor, "Serial Monitor", "Terminal-style serial port monitor with send/receive log", "IO", 0, 1)

SerialMonitor::SerialMonitor(QObject *parent) : Behaviours(parent)
{
    this->setWidth(380);
    this->setHeight(420);
    this->setContentHeight(420);
    this->setQmlBodyUrl("qrc:/behaviours/common/SerialMonitor.qml");
    this->addInputOutputExclusion(QList<QString>({
        "portChanged()",
        "connectedChanged()",
        "baudChanged()",
        "internalRxData(QString)",
        "internalTxData(QString)",
        "internalClear()"
    }));
}

void SerialMonitor::onPinsReady()
{
    // inputs
    setPinTypeForSignature("sendData(QString)",     Connections::StringType);
    setPinTypeForSignature("setBaud(int)",          Connections::IntType);
    setPinTypeForSignature("setPort(QString)",      Connections::StringType);
    setPinTypeForSignature("connectPort()",         Connections::FlowType);
    setPinTypeForSignature("disconnectPort()",      Connections::FlowType);
    setPinTypeForSignature("clear()",               Connections::FlowType);
    // outputs
    setPinTypeForSignature("outputReceived(QString)", Connections::StringType);
}

QMap<QString, QVariant> SerialMonitor::loadInfos()
{
    return SerialMonitor::static_infos();
}

QMap<QString, QVariant> SerialMonitor::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "SerialMonitor"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "SerialMonitor"},
        {"desc",          "Serial port terminal monitor"},
        {"inputs_count",  "0"},
        {"outputs_count", "1"}
    });
}

QString SerialMonitor::port()      const { return m_port; }
bool    SerialMonitor::connected() const { return m_connected; }
int     SerialMonitor::baud()      const { return m_baud; }

void SerialMonitor::sendData(const QString& data)
{
    emit internalTxData(data);
    emit outputReceived(data);
}

void SerialMonitor::setBaud(int baud)
{
    if (m_baud != baud) {
        m_baud = baud;
        emit baudChanged();
    }
}

void SerialMonitor::setPort(const QString& port)
{
    if (m_port != port) {
        m_port = port;
        emit portChanged();
    }
}

void SerialMonitor::connectPort()
{
    // Stub: real implementation would open QSerialPort
    if (!m_connected) {
        m_connected = true;
        emit connectedChanged();
    }
}

void SerialMonitor::disconnectPort()
{
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
}

void SerialMonitor::clear()
{
    emit internalClear();
}

QJsonObject SerialMonitor::saveState() const
{
    QJsonObject s;
    s["port"] = m_port;
    s["baud"] = m_baud;
    return s;
}

void SerialMonitor::loadState(const QJsonObject& s)
{
    if (s.contains("port")) setPort(s["port"].toString());
    if (s.contains("baud")) setBaud(s["baud"].toInt());
}
