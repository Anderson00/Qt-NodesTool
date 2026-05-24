#ifndef WEBSOCKETCLIENT_H
#define WEBSOCKETCLIENT_H

#include <QObject>
#include <QJsonObject>
#include <QTcpSocket>
#include <QTimer>
#include <QByteArray>
#include <behaviours/behaviours.h>

class WebSocketClient : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(bool    isConnected  READ isConnected  NOTIFY isConnectedChanged)
    Q_PROPERTY(QString url          READ url          NOTIFY urlChanged)
    Q_PROPERTY(int     messageCount READ messageCount NOTIFY messageCountChanged)
    Q_PROPERTY(bool    autoReconnect READ autoReconnect WRITE setAutoReconnect NOTIFY autoReconnectChanged)

public:
    explicit WebSocketClient(QObject *parent = nullptr);
    ~WebSocketClient();

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    bool    isConnected()  const { return m_connected; }
    QString url()          const { return m_url; }
    int     messageCount() const { return m_messageCount; }
    bool    autoReconnect() const { return m_autoReconnect; }
    void    setAutoReconnect(bool v);

public slots:
    void connectTo(QString url);
    void send(QString message);
    void disconnect();

signals:
    // node outputs
    void messageReceived(QString message);
    void connected();
    void disconnected();
    void error(QString msg);

    // QML bridge
    void internalMessage(QString message);
    void internalConnected();
    void internalDisconnected();
    void internalError(QString msg);

    // property notifiers
    void isConnectedChanged();
    void urlChanged();
    void messageCountChanged();
    void autoReconnectChanged();

private slots:
    void onSocketConnected();
    void onSocketReadyRead();
    void onSocketDisconnected();
    void onSocketError(QAbstractSocket::SocketError err);
    void onReconnectTimer();

private:
    void sendHandshake(const QUrl& wsUrl);
    bool parseHandshakeResponse();
    void processFrame(const QByteArray& data, int& consumed);
    QByteArray buildTextFrame(const QString& text);
    QByteArray buildPongFrame(const QByteArray& payload);
    QByteArray buildCloseFrame();

    QTcpSocket* m_socket = nullptr;
    QTimer      m_reconnectTimer;
    QByteArray  m_rxBuffer;

    QString m_url;
    bool    m_connected     = false;
    bool    m_handshakeDone = false;
    bool    m_autoReconnect = false;
    int     m_messageCount  = 0;
    QString m_wsKey;
};

#endif // WEBSOCKETCLIENT_H
