#include "constantvalue.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(ConstantValue, "Constant Value", "Outputs a user-defined constant value (number, text or boolean)", "common", 0, 4)

ConstantValue::ConstantValue(QObject *parent) : Behaviours(parent)
{
    this->setWidth(220);
    this->setHeight(180);
    this->setContentHeight(180);
    this->setQmlBodyUrl("qrc:/behaviours/common/ConstantValue.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "numericValueChanged()",
        "textValueChanged()",
        "boolValueChanged()",
        "modeChanged()"
    }));
}

QMap<QString, QVariant> ConstantValue::loadInfos()
{
    return ConstantValue::static_infos();
}

QMap<QString, QVariant> ConstantValue::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "ConstantValue"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "ConstantValue"},
        {"desc",          "Outputs a user-defined constant value"},
        {"inputs_count",  "0"},
        {"outputs_count", "4"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

double  ConstantValue::numericValue() const { return m_numericValue; }
QString ConstantValue::textValue()    const { return m_textValue; }
bool    ConstantValue::boolValue()    const { return m_boolValue; }
int     ConstantValue::mode()         const { return m_mode; }

// ── Setters ──────────────────────────────────────────────────────────────────

void ConstantValue::setNumericValue(double value) {
    if (!qFuzzyCompare(m_numericValue, value)) {
        m_numericValue = value;
        emit numericValueChanged();
    }
}

void ConstantValue::setTextValue(const QString& value) {
    if (m_textValue != value) {
        m_textValue = value;
        emit textValueChanged();
    }
}

void ConstantValue::setBoolValue(bool value) {
    if (m_boolValue != value) {
        m_boolValue = value;
        emit boolValueChanged();
    }
}

void ConstantValue::setMode(int mode) {
    if (m_mode != mode) {
        m_mode = mode;
        emit modeChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void ConstantValue::send() {
    switch (static_cast<Mode>(m_mode)) {
    case Numeric:
        emit outputValue(m_numericValue);
        emit outputInt(static_cast<int>(m_numericValue));
        emit outputString(QString::number(m_numericValue));
        emit outputBool(m_numericValue != 0.0);
        break;
    case Text:
        emit outputString(m_textValue);
        emit outputValue(m_textValue.toDouble());
        emit outputInt(m_textValue.toInt());
        emit outputBool(!m_textValue.isEmpty());
        break;
    case Boolean:
        emit outputBool(m_boolValue);
        emit outputValue(m_boolValue ? 1.0 : 0.0);
        emit outputInt(m_boolValue ? 1 : 0);
        emit outputString(m_boolValue ? "true" : "false");
        break;
    }
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject ConstantValue::saveState() const {
    QJsonObject s;
    s["mode"]         = m_mode;
    s["numericValue"] = m_numericValue;
    s["textValue"]    = m_textValue;
    s["boolValue"]    = m_boolValue;
    return s;
}

void ConstantValue::loadState(const QJsonObject& s) {
    if (s.contains("mode"))         setMode(s["mode"].toInt());
    if (s.contains("numericValue")) setNumericValue(s["numericValue"].toDouble());
    if (s.contains("textValue"))    setTextValue(s["textValue"].toString());
    if (s.contains("boolValue"))    setBoolValue(s["boolValue"].toBool());
}
