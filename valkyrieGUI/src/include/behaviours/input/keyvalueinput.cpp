#include "keyvalueinput.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(KeyValueInput, "Key/Value Input", "Sends a labeled value pair to connected chart/data nodes", "input", 1, 5)

KeyValueInput::KeyValueInput(QObject *parent) : Behaviours(parent)
{
    this->setWidth(260);
    this->setHeight(240);
    this->setContentHeight(240);
    this->setQmlBodyUrl("qrc:/behaviours/input/KeyValueInput.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setKeyText(QString)",
        "setValueNum(double)",
        "setIndexNum(int)",
        "setAutoSend(bool)",
        "keyTextChanged()",
        "valueNumChanged()",
        "indexNumChanged()",
        "autoSendChanged()"
    }));
}

void KeyValueInput::onPinsReady()
{
    // inputs
    setPinTypeForSignature("trigger()", Connections::FlowType);
    // outputs
    setPinTypeForSignature("outputLabelValue(QString,double)", Connections::AnyType);
    setPinTypeForSignature("outputIndexValue(int,double)",     Connections::AnyType);
    setPinTypeForSignature("outputString(QString)",            Connections::StringType);
    setPinTypeForSignature("outputValue(double)",              Connections::DoubleType);
    setPinTypeForSignature("outputData(QVariantList)",         Connections::ArrayType);
}

QMap<QString, QVariant> KeyValueInput::loadInfos()
{
    return KeyValueInput::static_infos();
}

QMap<QString, QVariant> KeyValueInput::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "KeyValueInput"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "KeyValueInput"},
        {"desc",          "Sends a labeled value pair to connected nodes"},
        {"inputs_count",  "1"},
        {"outputs_count", "5"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QString KeyValueInput::keyText()  const { return m_keyText; }
double  KeyValueInput::valueNum() const { return m_valueNum; }
int     KeyValueInput::indexNum() const { return m_indexNum; }
bool    KeyValueInput::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void KeyValueInput::setKeyText(const QString& key) {
    if (m_keyText != key) {
        m_keyText = key;
        emit keyTextChanged();
        if (m_autoSend) send();
    }
}

void KeyValueInput::setValueNum(double value) {
    if (!qFuzzyCompare(m_valueNum, value)) {
        m_valueNum = value;
        emit valueNumChanged();
        if (m_autoSend) send();
    }
}

void KeyValueInput::setIndexNum(int index) {
    if (m_indexNum != index) {
        m_indexNum = index;
        emit indexNumChanged();
        if (m_autoSend) send();
    }
}

void KeyValueInput::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void KeyValueInput::trigger() { send(); }

void KeyValueInput::send() {
    emit outputLabelValue(m_keyText, m_valueNum);
    emit outputIndexValue(m_indexNum, m_valueNum);
    emit outputString(m_keyText);
    emit outputValue(m_valueNum);
    emit outputData({m_keyText, m_valueNum});
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject KeyValueInput::saveState() const {
    QJsonObject s;
    s["keyText"]  = m_keyText;
    s["valueNum"] = m_valueNum;
    s["indexNum"] = m_indexNum;
    s["autoSend"] = m_autoSend;
    return s;
}

void KeyValueInput::loadState(const QJsonObject& s) {
    if (s.contains("keyText"))  setKeyText(s["keyText"].toString());
    if (s.contains("valueNum")) setValueNum(s["valueNum"].toDouble());
    if (s.contains("indexNum")) setIndexNum(s["indexNum"].toInt());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
