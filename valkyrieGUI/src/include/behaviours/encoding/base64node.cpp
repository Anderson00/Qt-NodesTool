#include "base64node.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(Base64Node, "Base64", "Encode and decode Base64 strings", "encoding", 2, 2)

Base64Node::Base64Node(QObject *parent)
    : Behaviours(parent)
    , m_urlSafe(false)
{
    this->setWidth(300);
    this->setHeight(220);
    this->setContentHeight(220);
    this->setQmlBodyUrl("qrc:/behaviours/encoding/Base64Node.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalEncoded(QString)",
        "internalDecoded(QString)"
    }));
}

void Base64Node::onPinsReady()
{
    // inputs
    setPinTypeForSignature("encode(QString)", Connections::StringType);
    setPinTypeForSignature("decode(QString)", Connections::StringType);
    // outputs
    setPinTypeForSignature("encoded(QString)",      Connections::StringType);
    setPinTypeForSignature("decodeResult(QString)", Connections::StringType);
}

QMap<QString, QVariant> Base64Node::loadInfos()
{
    return Base64Node::static_infos();
}

QMap<QString, QVariant> Base64Node::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "Base64Node"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "Base64Node"},
        {"desc",          "Encode and decode Base64 strings"},
        {"inputs_count",  "2"},
        {"outputs_count", "2"}
    });
}

void Base64Node::setLastEncoded(const QString& val)
{
    if (m_lastEncoded != val) {
        m_lastEncoded = val;
        emit lastEncodedChanged();
    }
}

void Base64Node::setLastDecoded(const QString& val)
{
    if (m_lastDecoded != val) {
        m_lastDecoded = val;
        emit lastDecodedChanged();
    }
}

void Base64Node::setUrlSafe(bool safe)
{
    if (m_urlSafe != safe) {
        m_urlSafe = safe;
        emit urlSafeChanged();
    }
}

void Base64Node::encode(QString input)
{
    QByteArray inputBytes = input.toUtf8();
    QByteArray::Base64Options options = m_urlSafe
        ? QByteArray::Base64UrlEncoding
        : QByteArray::Base64Encoding;

    QString result = QString::fromLatin1(inputBytes.toBase64(options));
    setLastEncoded(result);
    emit encoded(result);
    emit internalEncoded(result);
}

void Base64Node::decode(QString base64String)
{
    QByteArray::Base64Options options = m_urlSafe
        ? QByteArray::Base64UrlEncoding
        : QByteArray::Base64Encoding;

    QByteArray decodedBytes = QByteArray::fromBase64(base64String.toLatin1(), options);
    QString result = QString::fromUtf8(decodedBytes);
    setLastDecoded(result);
    emit decodeResult(result);
    emit internalDecoded(result);
}

QJsonObject Base64Node::saveState() const
{
    QJsonObject state;
    state["urlSafe"] = m_urlSafe;
    return state;
}

void Base64Node::loadState(const QJsonObject& state)
{
    if (state.contains("urlSafe"))
        setUrlSafe(state["urlSafe"].toBool(false));
}
