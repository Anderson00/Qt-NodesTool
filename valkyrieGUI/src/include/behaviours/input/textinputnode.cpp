#include "textinputnode.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(TextInputNode, "Text Input", "Sends a user-defined text string to connected nodes", "input", 1, 2)

TextInputNode::TextInputNode(QObject *parent) : Behaviours(parent)
{
    this->setWidth(240);
    this->setHeight(170);
    this->setContentHeight(170);
    this->setQmlBodyUrl("qrc:/behaviours/input/TextInputNode.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setText(QString)",
        "setAutoSend(bool)",
        "textChanged()",
        "autoSendChanged()"
    }));
}

void TextInputNode::onPinsReady()
{
    // inputs
    setPinTypeForSignature("trigger()", Connections::FlowType);
    // outputs
    setPinTypeForSignature("outputString(QString)",    Connections::StringType);
    setPinTypeForSignature("outputData(QVariantList)", Connections::ArrayType);
}

QMap<QString, QVariant> TextInputNode::loadInfos()
{
    return TextInputNode::static_infos();
}

QMap<QString, QVariant> TextInputNode::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "TextInputNode"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "TextInputNode"},
        {"desc",          "Sends a user-defined text string to connected nodes"},
        {"inputs_count",  "1"},
        {"outputs_count", "2"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QString TextInputNode::text()     const { return m_text; }
bool    TextInputNode::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void TextInputNode::setText(const QString& value) {
    if (m_text != value) {
        m_text = value;
        emit textChanged();
        if (m_autoSend) send();
    }
}

void TextInputNode::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void TextInputNode::send() {
    emit outputString(m_text);
    emit outputData({m_text});
}
void TextInputNode::trigger() { send(); }

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject TextInputNode::saveState() const {
    QJsonObject s;
    s["text"]      = m_text;
    s["autoSend"]  = m_autoSend;
    return s;
}

void TextInputNode::loadState(const QJsonObject& s) {
    if (s.contains("text"))     setText(s["text"].toString());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
