#include "numberinput.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(NumberInput, "Number Input", "Sends a numeric value (double, int, bool or string) to connected nodes", "input", 1, 5)

NumberInput::NumberInput(QObject *parent) : Behaviours(parent)
{
    this->setWidth(240);
    this->setHeight(240);
    this->setContentHeight(240);
    this->setQmlBodyUrl("qrc:/behaviours/input/NumberInput.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setValue(double)",
        "setAutoSend(bool)",
        "setStepSize(double)",
        "setMinValue(double)",
        "setMaxValue(double)",
        "valueChanged()",
        "autoSendChanged()",
        "stepSizeChanged()",
        "minValueChanged()",
        "maxValueChanged()"
    }));
}

void NumberInput::onPinsReady()
{
    // inputs
    setPinTypeForSignature("trigger()", Connections::FlowType);
    // outputs
    setPinTypeForSignature("outputValue(double)",    Connections::DoubleType);
    setPinTypeForSignature("outputInt(int)",          Connections::IntType);
    setPinTypeForSignature("outputBool(bool)",        Connections::BoolType);
    setPinTypeForSignature("outputString(QString)",   Connections::StringType);
    setPinTypeForSignature("outputData(QVariantList)",Connections::ArrayType);
}

QMap<QString, QVariant> NumberInput::loadInfos()
{
    return NumberInput::static_infos();
}

QMap<QString, QVariant> NumberInput::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "NumberInput"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "NumberInput"},
        {"desc",          "Sends a numeric value to connected nodes"},
        {"inputs_count",  "1"},
        {"outputs_count", "5"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

double NumberInput::value()    const { return m_value; }
bool   NumberInput::autoSend() const { return m_autoSend; }
double NumberInput::stepSize() const { return m_stepSize; }
double NumberInput::minValue() const { return m_minValue; }
double NumberInput::maxValue() const { return m_maxValue; }

// ── Setters ──────────────────────────────────────────────────────────────────

void NumberInput::setValue(double v) {
    double clamped = qBound(m_minValue, v, m_maxValue);
    if (!qFuzzyCompare(m_value, clamped)) {
        m_value = clamped;
        emit valueChanged();
        if (m_autoSend) send();
    }
}

void NumberInput::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

void NumberInput::setStepSize(double step) {
    if (!qFuzzyCompare(m_stepSize, step) && step > 0) {
        m_stepSize = step;
        emit stepSizeChanged();
    }
}

void NumberInput::setMinValue(double min) {
    if (!qFuzzyCompare(m_minValue, min)) {
        m_minValue = min;
        emit minValueChanged();
    }
}

void NumberInput::setMaxValue(double max) {
    if (!qFuzzyCompare(m_maxValue, max)) {
        m_maxValue = max;
        emit maxValueChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void NumberInput::trigger() { send(); }

void NumberInput::send() {
    emit outputValue(m_value);
    emit outputInt(static_cast<int>(m_value));
    emit outputBool(m_value != 0.0);
    emit outputString(QString::number(m_value));
    emit outputData({m_value});
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject NumberInput::saveState() const {
    QJsonObject s;
    s["value"]     = m_value;
    s["autoSend"]  = m_autoSend;
    s["stepSize"]  = m_stepSize;
    s["minValue"]  = m_minValue;
    s["maxValue"]  = m_maxValue;
    return s;
}

void NumberInput::loadState(const QJsonObject& s) {
    if (s.contains("stepSize")) setStepSize(s["stepSize"].toDouble());
    if (s.contains("minValue")) setMinValue(s["minValue"].toDouble());
    if (s.contains("maxValue")) setMaxValue(s["maxValue"].toDouble());
    if (s.contains("value"))    setValue(s["value"].toDouble());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
