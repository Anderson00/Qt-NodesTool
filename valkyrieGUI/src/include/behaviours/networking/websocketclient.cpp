#include "websocketclient.h"
#include "behaviours/behaviourregistry.h"

#include <QUrl>
#include <QRandomGenerator>
#include <QCryptographicHash>
#include <QAbstractSocket>

REGISTER_BEHAVIOUR(WebSocketClient, "WebSocket Client", "Bidirectional WebSocket connection for real-time streaming", "networking", 3, 4)

WebSocketClient::WebSocketClient(QObject *parent) : Behaviours(parent)
{
    setWidth(340);
    setHeight(300);
    setContentHeight(300);
    setQmlBodyUrl("qrc:/behaviours/networking/WebSocketClient.qml");
    addInputOutputExclusion(QList<QString>({
        "internalMessage(QString)",
        "internalConnected()",
        "internalDisconnected()",
        "internalError(QString)"
    }));

    m_reconnectTimer.setSingleShot(true);
    m_reconnectTimer.setInterval(3000);
    connect(&m_reconnectTimer, &QTimer::timeout, this, &WebSocketClient::onReconnectTimer);
}

WebSocketClient::~WebSocketClient()
{
    if (m_socket) {
        m_socket->disconnectFromHost();
        m_socket->deleteLater();
    }
}

QMap<QString, QVariant> WebSocketClient::loadInfos() { return WebSocketClient::static_infos(); }

QMap<QString, QVariant> WebSocketClient::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "WebSocketClient"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "WebSocketClient"},
        {"desc",          "Bidirectional WebSocket connection for real-time streaming"},
        {"inputs_count",  "3"},
        {"outputs_count", "4"}
    });
}

// ── Public slots ──────────────────────────────────────────────────────────────

void WebSocketClient::connectTo(QString url)
{
    m_url = url;
    emit urlChanged();

    if (m_socket) {
        m_socket->disconnectFromHost();
        m_socket->deleteLater();
    }

    m_socket = new QTcpSocket(this);
    m_connected     = false;
    m_handshakeDone = false;
    m_rxBuffer.clear();

    connect(m_socket, &QTcpSocket::connected,    this, &WebSocketClient::onSocketConnected);
    connect(m_socket, &QTcpSocket::readyRead,    this, &WebSocketClient::onSocketReadyRead);
    connect(m_socket, &QTcpSocket::disconnected, this, &WebSocketClient::onSocketDisconnected);
    connect(m_socket, &QAbstractSocket::errorOccurred, this, &WebSocketClient::onSocketError);

    QUrl parsed(url);
    quint16 port = static_cast<quint16>(parsed.port(-1));
    if (port == static_cast<quint16>(-1))
        port = (parsed.scheme() == "wss") ? 443 : 80;

    m_socket->connectToHost(parsed.host(), port);
}

void WebSocketClient::send(QString message)
{
    if (!m_connected || !m_handshakeDone || !m_socket) return;
    m_socket->write(buildTextFrame(message));
}

void WebSocketClient::disconnect()
{
    m_autoReconnect = false;
    m_reconnectTimer.stop();
    if (m_socket) {
        if (m_handshakeDone)
            m_socket->write(buildCloseFrame());
        m_socket->disconnectFromHost();
    }
}

void WebSocketClient::setAutoReconnect(bool v)
{
    if (m_autoReconnect != v) {
        m_autoReconnect = v;
        emit autoReconnectChanged();
    }
}

// ── Private slots ─────────────────────────────────────────────────────────────

void WebSocketClient::onSocketConnected()
{
    sendHandshake(QUrl(m_url));
}

void WebSocketClient::onSocketReadyRead()
{
    m_rxBuffer.append(m_socket->readAll());

    if (!m_handshakeDone) {
        if (parseHandshakeResponse()) {
            m_handshakeDone = true;
            m_connected = true;
            m_messageCount = 0;
            emit isConnectedChanged();
            emit connected();
            emit internalConnected();
        }
        return;
    }

    int consumed = 0;
    while (consumed < m_rxBuffer.size())
        processFrame(m_rxBuffer, consumed);

    if (consumed > 0)
        m_rxBuffer.remove(0, consumed);
}

void WebSocketClient::onSocketDisconnected()
{
    bool wasConnected = m_connected;
    m_connected     = false;
    m_handshakeDone = false;
    emit isConnectedChanged();
    if (wasConnected) {
        emit disconnected();
        emit internalDisconnected();
    }
    if (m_autoReconnect)
        m_reconnectTimer.start();
}

void WebSocketClient::onSocketError(QAbstractSocket::SocketError)
{
    QString msg = m_socket ? m_socket->errorString() : "Unknown error";
    emit error(msg);
    emit internalError(msg);
}

void WebSocketClient::onReconnectTimer()
{
    if (!m_url.isEmpty())
        connectTo(m_url);
}

// ── Handshake ─────────────────────────────────────────────────────────────────

void WebSocketClient::sendHandshake(const QUrl& wsUrl)
{
    // Generate a random 16-byte base64 key
    QByteArray keyBytes(16, Qt::Uninitialized);
    QRandomGenerator::global()->fillRange(
        reinterpret_cast<quint32*>(keyBytes.data()),
        static_cast<qsizetype>(keyBytes.size() / sizeof(quint32))
    );
    m_wsKey = keyBytes.toBase64();

    QString path = wsUrl.path().isEmpty() ? "/" : wsUrl.path();
    if (!wsUrl.query().isEmpty()) path += "?" + wsUrl.query();

    QString host = wsUrl.host();
    if (wsUrl.port(-1) != -1) host += ":" + QString::number(wsUrl.port());

    QString req =
        "GET " + path + " HTTP/1.1\r\n"
        "Host: " + host + "\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        "Sec-WebSocket-Key: " + m_wsKey + "\r\n"
        "Sec-WebSocket-Version: 13\r\n"
        "\r\n";

    m_socket->write(req.toUtf8());
}

bool WebSocketClient::parseHandshakeResponse()
{
    int headerEnd = m_rxBuffer.indexOf("\r\n\r\n");
    if (headerEnd < 0) return false;

    QString response = QString::fromUtf8(m_rxBuffer.left(headerEnd));
    m_rxBuffer.remove(0, headerEnd + 4);

    if (!response.startsWith("HTTP/1.1 101")) return false;

    // Verify Sec-WebSocket-Accept
    QByteArray expectedAccept = QCryptographicHash::hash(
        (m_wsKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").toUtf8(),
        QCryptographicHash::Sha1
    ).toBase64();

    return response.contains("Sec-WebSocket-Accept: " + QString::fromUtf8(expectedAccept));
}

// ── Frame processing ──────────────────────────────────────────────────────────

void WebSocketClient::processFrame(const QByteArray& data, int& consumed)
{
    if (data.size() - consumed < 2) return;

    const quint8* buf = reinterpret_cast<const quint8*>(data.constData()) + consumed;
    bool fin    = (buf[0] & 0x80) != 0;
    quint8 op   = buf[0] & 0x0F;
    bool masked = (buf[1] & 0x80) != 0;
    quint64 len = buf[1] & 0x7F;

    int headerSize = 2;
    if (len == 126) {
        if (data.size() - consumed < 4) return;
        len = (static_cast<quint64>(buf[2]) << 8) | buf[3];
        headerSize = 4;
    } else if (len == 127) {
        if (data.size() - consumed < 10) return;
        len = 0;
        for (int i = 0; i < 8; ++i) len = (len << 8) | buf[2+i];
        headerSize = 10;
    }

    int maskOffset = headerSize;
    if (masked) headerSize += 4;

    if (static_cast<quint64>(data.size() - consumed) < static_cast<quint64>(headerSize) + len) return;

    QByteArray payload;
    payload.resize(static_cast<int>(len));
    if (masked) {
        const quint8* mask = buf + maskOffset;
        for (quint64 i = 0; i < len; ++i)
            payload[static_cast<int>(i)] = buf[headerSize + i] ^ mask[i % 4];
    } else {
        payload = data.mid(consumed + headerSize, static_cast<int>(len));
    }

    consumed += headerSize + static_cast<int>(len);

    switch (op) {
    case 0x1: // text frame
        if (fin) {
            QString msg = QString::fromUtf8(payload);
            ++m_messageCount;
            emit messageCountChanged();
            emit messageReceived(msg);
            emit internalMessage(msg);
        }
        break;
    case 0x8: // close
        m_socket->write(buildCloseFrame());
        m_socket->disconnectFromHost();
        break;
    case 0x9: // ping
        m_socket->write(buildPongFrame(payload));
        break;
    default:
        break;
    }
}

// ── Frame builders ────────────────────────────────────────────────────────────

QByteArray WebSocketClient::buildTextFrame(const QString& text)
{
    QByteArray payload = text.toUtf8();
    QByteArray frame;
    frame.append(static_cast<char>(0x81)); // FIN + text opcode

    quint8 maskBuf[4];
    QRandomGenerator::global()->fillRange(maskBuf, 4);

    int len = payload.size();
    if (len < 126) {
        frame.append(static_cast<char>(0x80 | len));
    } else if (len < 65536) {
        frame.append(static_cast<char>(0x80 | 126));
        frame.append(static_cast<char>((len >> 8) & 0xFF));
        frame.append(static_cast<char>(len & 0xFF));
    } else {
        frame.append(static_cast<char>(0x80 | 127));
        for (int i = 7; i >= 0; --i)
            frame.append(static_cast<char>((len >> (i*8)) & 0xFF));
    }

    frame.append(reinterpret_cast<const char*>(maskBuf), 4);
    for (int i = 0; i < len; ++i)
        frame.append(payload[i] ^ maskBuf[i % 4]);

    return frame;
}

QByteArray WebSocketClient::buildPongFrame(const QByteArray& payload)
{
    QByteArray frame;
    frame.append(static_cast<char>(0x8A)); // FIN + pong
    frame.append(static_cast<char>(payload.size() & 0x7F));
    frame.append(payload);
    return frame;
}

QByteArray WebSocketClient::buildCloseFrame()
{
    QByteArray frame;
    frame.append(static_cast<char>(0x88)); // FIN + close
    frame.append(static_cast<char>(0x00));
    return frame;
}

// ── Persistence ───────────────────────────────────────────────────────────────

QJsonObject WebSocketClient::saveState() const
{
    QJsonObject state;
    if (!m_url.isEmpty()) state["url"] = m_url;
    state["autoReconnect"] = m_autoReconnect;
    return state;
}

void WebSocketClient::loadState(const QJsonObject& state)
{
    setAutoReconnect(state["autoReconnect"].toBool(false));
    if (state.contains("url")) {
        m_url = state["url"].toString();
        emit urlChanged();
    }
}
