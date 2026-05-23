#include "arrayinput.h"
#include "behaviours/behaviourregistry.h"
#include <QJsonArray>
#include <QJsonDocument>

REGISTER_BEHAVIOUR(ArrayInput, "Array Input", "Builds and sends a list of string values to connected nodes", "input", 1, 3)

ArrayInput::ArrayInput(QObject *parent) : Behaviours(parent)
{
    this->setWidth(260);
    this->setHeight(280);
    this->setContentHeight(280);
    this->setQmlBodyUrl("qrc:/behaviours/input/ArrayInput.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "addItem(QString)",
        "removeItem(int)",
        "setItem(int,QString)",
        "clearItems()",
        "setAutoSend(bool)",
        "itemsChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> ArrayInput::loadInfos()
{
    return ArrayInput::static_infos();
}

QMap<QString, QVariant> ArrayInput::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "ArrayInput"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "ArrayInput"},
        {"desc",          "Builds and sends a list of string values"},
        {"inputs_count",  "1"},
        {"outputs_count", "3"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QVariantList ArrayInput::items()    const { return m_items; }
bool         ArrayInput::autoSend() const { return m_autoSend; }

// ── Mutators ─────────────────────────────────────────────────────────────────

void ArrayInput::addItem(const QString& value) {
    m_items.append(value);
    emit itemsChanged();
    if (m_autoSend) send();
}

void ArrayInput::removeItem(int index) {
    if (index >= 0 && index < m_items.size()) {
        m_items.removeAt(index);
        emit itemsChanged();
        if (m_autoSend) send();
    }
}

void ArrayInput::setItem(int index, const QString& value) {
    if (index >= 0 && index < m_items.size()) {
        m_items[index] = value;
        emit itemsChanged();
        if (m_autoSend) send();
    }
}

void ArrayInput::clearItems() {
    if (!m_items.isEmpty()) {
        m_items.clear();
        emit itemsChanged();
        if (m_autoSend) send();
    }
}

void ArrayInput::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void ArrayInput::trigger() { send(); }

void ArrayInput::send() {
    QJsonArray arr;
    for (const QVariant& v : m_items)
        arr.append(v.toString());
    const QString json = QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact));

    emit outputArray(m_items);
    emit outputString(json);
    emit outputCount(m_items.size());
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject ArrayInput::saveState() const {
    QJsonArray arr;
    for (const QVariant& v : m_items)
        arr.append(v.toString());

    QJsonObject s;
    s["items"]    = arr;
    s["autoSend"] = m_autoSend;
    return s;
}

void ArrayInput::loadState(const QJsonObject& s) {
    if (s.contains("items")) {
        m_items.clear();
        for (const QJsonValue& v : s["items"].toArray())
            m_items.append(v.toString());
        emit itemsChanged();
    }
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
