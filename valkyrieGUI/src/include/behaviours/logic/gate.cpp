#include "gate.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(Gate, "Gate", "Conditional pass/block — forwards or blocks values based on a boolean", "logic", 3, 2)

Gate::Gate(QObject *parent) : Behaviours(parent)
{
    setWidth(200);
    setHeight(170);
    setContentHeight(170);
    setQmlBodyUrl("qrc:/behaviours/logic/Gate.qml");
    addInputOutputExclusion({"toggle()","resetCounts()","gateChanged()","lastInputChanged()","passCountChanged()","blockCountChanged()"});
}

QMap<QString, QVariant> Gate::loadInfos() { return static_infos(); }

QMap<QString, QVariant> Gate::static_infos() {
    return {{"name","Gate"},{"type",Behaviours::Type::CPP},{"className","Gate"},{"desc","Conditional pass/block for values"},{"inputs_count","3"},{"outputs_count","2"}};
}

bool   Gate::gateOpen()   const { return m_gateOpen; }
double Gate::lastInput()  const { return m_lastInput; }
int    Gate::passCount()  const { return m_passCount; }
int    Gate::blockCount() const { return m_blockCount; }

void Gate::setGate(bool open) {
    if(m_gateOpen!=open){ m_gateOpen=open; emit gateChanged(); }
}

void Gate::setInput(double value) {
    m_lastInput = value;
    emit lastInputChanged();
    if(m_gateOpen) {
        m_passCount++; emit passCountChanged();
        emit outputValue(value);
    } else {
        m_blockCount++; emit blockCountChanged();
        emit outputBlocked(value);
    }
}

void Gate::toggle() { setGate(!m_gateOpen); }

void Gate::resetCounts() {
    m_passCount=0; m_blockCount=0;
    emit passCountChanged(); emit blockCountChanged();
}

QJsonObject Gate::saveState() const { return {{"gateOpen",m_gateOpen}}; }
void Gate::loadState(const QJsonObject& s) {
    if(s.contains("gateOpen")) setGate(s["gateOpen"].toBool(true));
}
