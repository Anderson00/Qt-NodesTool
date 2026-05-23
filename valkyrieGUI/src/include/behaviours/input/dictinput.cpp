#include "dictinput.h"
#include "behaviours/behaviourregistry.h"
#include <QJsonDocument>

REGISTER_BEHAVIOUR(DictInput, "Dict Input", "Builds and sends a key/value dictionary to connected nodes", "input", 1, 4)

DictInput::DictInput(QObject *parent) : Behaviours(parent)
{
    this->setWidth(280);
    this->setHeight(300);
    this->setContentHeight(300);
    this->setQmlBodyUrl("qrc:/behaviours/input/DictInput.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setEntry(QString,QString)",
        "removeEntry(QString)",
        "clearDict()",
        "setAutoSend(bool)",
        "dictChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> DictInput::loadInfos()
{
    return DictInput::static_infos();
}

QMap<QString, QVariant> DictInput::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "DictInput"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "DictInput"},
        {"desc",          "Builds and sends a key/value dictionary"},
        {"inputs_count",  "1"},
        {"outputs_count", "4"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QVariantMap DictInput::dict()     const { return m_dict; }
bool        DictInput::autoSend() const { return m_autoSend; }

// ── Mutators ─────────────────────────────────────────────────────────────────

void DictInput::setEntry(const QString& key, const QString& value) {
    if (key.isEmpty()) return;
    m_dict[key] = value;
    emit dictChanged();
    if (m_autoSend) send();
}

void DictInput::removeEntry(const QString& key) {
    if (m_dict.remove(key) > 0) {
        emit dictChanged();
        if (m_autoSend) send();
    }
}

void DictInput::clearDict() {
    if (!m_dict.isEmpty()) {
        m_dict.clear();
        emit dictChanged();
        if (m_autoSend) send();
    }
}

void DictInput::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void DictInput::trigger() { send(); }

void DictInput::send() {
    QJsonObject obj;
    for (auto it = m_dict.constBegin(); it != m_dict.constEnd(); ++it)
        obj[it.key()] = it.value().toString();
    const QString json = QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact));

    emit outputDict(m_dict);
    emit outputString(json);
    emit outputCount(m_dict.size());
    emit outputData({QVariant(m_dict)});  // universal port: single QVariantMap element
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject DictInput::saveState() const {
    QJsonObject entries;
    for (auto it = m_dict.constBegin(); it != m_dict.constEnd(); ++it)
        entries[it.key()] = it.value().toString();

    QJsonObject s;
    s["dict"]     = entries;
    s["autoSend"] = m_autoSend;
    return s;
}

void DictInput::loadState(const QJsonObject& s) {
    if (s.contains("dict")) {
        m_dict.clear();
        const QJsonObject entries = s["dict"].toObject();
        for (auto it = entries.constBegin(); it != entries.constEnd(); ++it)
            m_dict[it.key()] = it.value().toString();
        emit dictChanged();
    }
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
