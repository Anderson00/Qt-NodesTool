#include "hashgenerator.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(HashGenerator, "Hash Generator", "Compute MD5/SHA1/SHA256/SHA512 hash of input text", "encoding", 2, 1)

HashGenerator::HashGenerator(QObject *parent)
    : Behaviours(parent)
    , m_algorithm("sha256")
{
    this->setWidth(300);
    this->setHeight(220);
    this->setContentHeight(220);
    this->setQmlBodyUrl("qrc:/behaviours/encoding/HashGenerator.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalHashReady(QString)",
        "internalAlgorithmChanged(QString)"
    }));
}

QMap<QString, QVariant> HashGenerator::loadInfos()
{
    return HashGenerator::static_infos();
}

QMap<QString, QVariant> HashGenerator::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "HashGenerator"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "HashGenerator"},
        {"desc",          "Compute MD5/SHA1/SHA256/SHA512 hash of input text"},
        {"inputs_count",  "2"},
        {"outputs_count", "1"}
    });
}

void HashGenerator::setLastHash(const QString& h)
{
    if (m_lastHash != h) {
        m_lastHash = h;
        emit lastHashChanged();
    }
}

void HashGenerator::setAlgorithm(QString alg)
{
    if (m_algorithm != alg) {
        m_algorithm = alg;
        emit algorithmChanged();
        emit internalAlgorithmChanged(alg);
    }
}

void HashGenerator::hash(QString input)
{
    static const QMap<QString, QCryptographicHash::Algorithm> algoMap = {
        {"md5",    QCryptographicHash::Md5},
        {"sha1",   QCryptographicHash::Sha1},
        {"sha256", QCryptographicHash::Sha256},
        {"sha512", QCryptographicHash::Sha512}
    };

    QCryptographicHash::Algorithm algo = algoMap.value(m_algorithm, QCryptographicHash::Sha256);
    QString hexResult = QCryptographicHash::hash(input.toUtf8(), algo).toHex();

    setLastHash(hexResult);
    emit hashReady(hexResult);
    emit internalHashReady(hexResult);
}

QJsonObject HashGenerator::saveState() const
{
    QJsonObject state;
    state["algorithm"] = m_algorithm;
    return state;
}

void HashGenerator::loadState(const QJsonObject& state)
{
    if (state.contains("algorithm"))
        setAlgorithm(state["algorithm"].toString());
}
