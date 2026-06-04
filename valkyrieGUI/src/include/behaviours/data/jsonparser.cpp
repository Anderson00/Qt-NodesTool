#include "jsonparser.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(JSONParser, "JSON Parser", "Extract values from JSON using dot-path notation", "data", 2, 3)

JSONParser::JSONParser(QObject *parent)
    : Behaviours(parent)
{
    this->setWidth(320);
    this->setHeight(260);
    this->setContentHeight(260);
    this->setQmlBodyUrl("qrc:/behaviours/data/JSONParser.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalResult(QString,QString)",
        "internalError(QString)",
        "internalKeys(QStringList)"
    }));
}

void JSONParser::onPinsReady()
{
    // inputs
    setPinTypeForSignature("parse(QString)",   Connections::StringType);
    setPinTypeForSignature("setPath(QString)", Connections::StringType);
    // outputs
    setPinTypeForSignature("valueExtracted(QString)", Connections::StringType);
    setPinTypeForSignature("error(QString)",           Connections::StringType);
    setPinTypeForSignature("allKeys(QStringList)",     Connections::ArrayType);
}

QMap<QString, QVariant> JSONParser::loadInfos()
{
    return JSONParser::static_infos();
}

QMap<QString, QVariant> JSONParser::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "JSONParser"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "JSONParser"},
        {"desc",          "Extract values from JSON using dot-path notation"},
        {"inputs_count",  "2"},
        {"outputs_count", "3"}
    });
}

QString JSONParser::currentPath() const { return m_currentPath; }
QString JSONParser::lastResult()  const { return m_lastResult; }
QString JSONParser::lastError()   const { return m_lastError; }

void JSONParser::parse(QString json)
{
    m_lastJson = json;
    processJson(json, m_currentPath);
}

void JSONParser::setPath(QString dotPath)
{
    if (m_currentPath != dotPath) {
        m_currentPath = dotPath;
        emit currentPathChanged();
    }
    if (!m_lastJson.isEmpty()) {
        processJson(m_lastJson, dotPath);
    }
}

void JSONParser::processJson(const QString& json, const QString& path)
{
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8(), &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        QString errMsg = "Parse error: " + parseError.errorString();
        m_lastError = errMsg;
        emit lastErrorChanged();
        emit error(errMsg);
        emit internalError(errMsg);
        return;
    }

    // Emit top-level keys
    if (doc.isObject()) {
        QStringList keys = doc.object().keys();
        emit allKeys(keys);
        emit internalKeys(keys);
    } else if (doc.isArray()) {
        QStringList keys;
        for (int i = 0; i < doc.array().size(); i++)
            keys << QString::number(i);
        emit allKeys(keys);
        emit internalKeys(keys);
    }

    // Extract path value
    if (path.isEmpty()) {
        QString result = QString::fromUtf8(doc.toJson(QJsonDocument::Compact));
        m_lastResult = result;
        emit lastResultChanged();
        emit valueExtracted(result);
        emit internalResult(path, result);
        return;
    }

    QStringList parts = path.split(".", Qt::SkipEmptyParts);
    QJsonValue root;
    if (doc.isObject()) root = QJsonValue(doc.object());
    else if (doc.isArray()) root = QJsonValue(doc.array());

    QString result = extractPath(root, parts);

    if (!m_lastError.isEmpty() && m_lastError.startsWith("Path")) {
        // error already emitted in extractPath
        return;
    }

    m_lastResult = result;
    emit lastResultChanged();
    emit valueExtracted(result);
    emit internalResult(path, result);
}

QString JSONParser::extractPath(const QJsonValue& root, const QStringList& parts) const
{
    if (parts.isEmpty()) {
        if (root.isObject()) {
            return QString::fromUtf8(QJsonDocument(root.toObject()).toJson(QJsonDocument::Compact));
        } else if (root.isArray()) {
            return QString::fromUtf8(QJsonDocument(root.toArray()).toJson(QJsonDocument::Compact));
        } else if (root.isString()) {
            return root.toString();
        } else if (root.isBool()) {
            return root.toBool() ? "true" : "false";
        } else if (root.isNull()) {
            return "null";
        } else {
            return QString::number(root.toDouble());
        }
    }

    const QString& key = parts.first();
    QStringList remaining = parts.mid(1);

    if (root.isObject()) {
        QJsonObject obj = root.toObject();
        if (!obj.contains(key)) {
            return QString();
        }
        return extractPath(obj[key], remaining);
    } else if (root.isArray()) {
        bool ok = false;
        int idx = key.toInt(&ok);
        if (!ok) {
            return QString();
        }
        QJsonArray arr = root.toArray();
        if (idx < 0 || idx >= arr.size()) {
            return QString();
        }
        return extractPath(arr[idx], remaining);
    }

    return QString();
}

QJsonObject JSONParser::saveState() const
{
    QJsonObject state;
    state["currentPath"] = m_currentPath;
    state["lastJson"]    = m_lastJson;
    return state;
}

void JSONParser::loadState(const QJsonObject& state)
{
    if (state.contains("currentPath")) {
        m_currentPath = state["currentPath"].toString();
        emit currentPathChanged();
    }
    if (state.contains("lastJson")) {
        m_lastJson = state["lastJson"].toString();
    }
}
