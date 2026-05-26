#include "numbercast.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(NumberCast, "Number Cast", "Converts a numeric value between int, double, bool and string types", "converters", 3, 5)

NumberCast::NumberCast(QObject *parent) : Behaviours(parent)
{
    this->setWidth(220);
    this->setHeight(160);
    this->setContentHeight(160);
    this->setQmlBodyUrl("qrc:/behaviours/converters/NumberCast.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setAutoSend(bool)",
        "valueChanged()",
        "autoSendChanged()"
    }));
}

void NumberCast::onPinsReady()
{
    // inputs
    setPinTypeForSignature("trigger()",        Connections::FlowType);
    setPinTypeForSignature("setInput(double)", Connections::DoubleType);
    setPinTypeForSignature("setInputInt(int)", Connections::IntType);
    // outputs
    setPinTypeForSignature("outputDouble(double)", Connections::DoubleType);
    setPinTypeForSignature("outputInt(int)",        Connections::IntType);
    setPinTypeForSignature("outputBool(bool)",      Connections::BoolType);
    setPinTypeForSignature("outputString(QString)", Connections::StringType);
    setPinTypeForSignature("outputData(QVariantList)", Connections::ArrayType);
}

QMap<QString, QVariant> NumberCast::loadInfos()
{
    return NumberCast::static_infos();
}

QMap<QString, QVariant> NumberCast::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "NumberCast"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "NumberCast"},
        {"desc",          "Converts numeric value between int, double, bool and string"},
        {"inputs_count",  "3"},
        {"outputs_count", "5"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

double NumberCast::value()    const { return m_value; }
bool   NumberCast::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void NumberCast::setInput(double v) {
    if (!qFuzzyCompare(m_value, v)) {
        m_value = v;
        emit valueChanged();
        if (m_autoSend) send();
    }
}

void NumberCast::setInputInt(int v) {
    setInput(double(v));
}

void NumberCast::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void NumberCast::trigger() { send(); }

void NumberCast::send() {
    emit outputDouble(m_value);
    emit outputInt(static_cast<int>(m_value));
    emit outputBool(m_value != 0.0);
    emit outputString(QString::number(m_value));
    emit outputData({m_value});
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject NumberCast::saveState() const {
    QJsonObject s;
    s["value"]     = m_value;
    s["autoSend"]  = m_autoSend;
    return s;
}

void NumberCast::loadState(const QJsonObject& s) {
    if (s.contains("value"))    setInput(s["value"].toDouble());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
