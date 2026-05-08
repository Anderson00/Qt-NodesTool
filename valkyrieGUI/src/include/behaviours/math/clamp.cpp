#include "clamp.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(Clamp, "Clamp", "Constrains a value between min and max, outputs normalized 0..1", "math", 3, 2)

Clamp::Clamp(QObject *parent) : Behaviours(parent)
{
    setWidth(220);
    setHeight(180);
    setContentHeight(180);
    setQmlBodyUrl("qrc:/behaviours/math/Clamp.qml");
    addInputOutputExclusion({"inputValueChanged()","rangeMinChanged()","rangeMaxChanged()","clampedValueChanged()","normalizedChanged()"});
}

QMap<QString, QVariant> Clamp::loadInfos() { return static_infos(); }

QMap<QString, QVariant> Clamp::static_infos() {
    return {{"name","Clamp"},{"type",Behaviours::Type::CPP},{"className","Clamp"},{"desc","Constrains value between min/max"},{"inputs_count","3"},{"outputs_count","2"}};
}

double Clamp::inputValue()   const { return m_inputValue; }
double Clamp::rangeMin()     const { return m_min; }
double Clamp::rangeMax()     const { return m_max; }
double Clamp::clampedValue() const { return m_clamped; }
double Clamp::normalized()   const { return m_normalized; }

void Clamp::setInput(double value) { m_inputValue = value; emit inputValueChanged(); compute(); }
void Clamp::setMin(double min) { if(!qFuzzyCompare(m_min,min)){m_min=min; emit rangeMinChanged(); compute();} }
void Clamp::setMax(double max) { if(!qFuzzyCompare(m_max,max)){m_max=max; emit rangeMaxChanged(); compute();} }

void Clamp::compute() {
    double actualMin = qMin(m_min, m_max);
    double actualMax = qMax(m_min, m_max);
    m_clamped = qBound(actualMin, m_inputValue, actualMax);
    double range = actualMax - actualMin;
    m_normalized = (range > 0.0) ? (m_clamped - actualMin) / range : 0.0;
    emit clampedValueChanged(); emit normalizedChanged();
    emit outputValue(m_clamped); emit outputNormalized(m_normalized);
}

QJsonObject Clamp::saveState() const { return {{"min",m_min},{"max",m_max}}; }
void Clamp::loadState(const QJsonObject& s) {
    if(s.contains("min")) setMin(s["min"].toDouble());
    if(s.contains("max")) setMax(s["max"].toDouble());
}
