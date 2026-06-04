#include "flowswitch.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(FlowSwitch, "Flow Switch", "Routes execution to one of N cases based on an integer value", "flow", 2, 5)

FlowSwitch::FlowSwitch(QObject *parent) : Behaviours(parent)
{
    setWidth(220); setHeight(220); setContentHeight(220);
    setQmlBodyUrl("qrc:/behaviours/flow/FlowSwitchViewer.qml");
    addInputOutputExclusion({"switchValueChanged()","lastCaseChanged()"});
}

void FlowSwitch::onPinsReady()
{
    // inputs
    setPinTypeForSignature("trigger()",     Connections::FlowType);
    setPinTypeForSignature("setValue(int)", Connections::IntType);
    // outputs
    setPinTypeForSignature("case0()",       Connections::FlowType);
    setPinTypeForSignature("case1()",       Connections::FlowType);
    setPinTypeForSignature("case2()",       Connections::FlowType);
    setPinTypeForSignature("case3()",       Connections::FlowType);
    setPinTypeForSignature("caseDefault()", Connections::FlowType);
}

QMap<QString, QVariant> FlowSwitch::loadInfos() { return static_infos(); }
QMap<QString, QVariant> FlowSwitch::static_infos() {
    return {{"name","Flow Switch"},{"type",Behaviours::CPP},{"className","FlowSwitch"},
            {"desc","Routes execution to one of N cases based on an integer value"},{"inputs_count","2"},{"outputs_count","5"}};
}

void FlowSwitch::trigger() {
    m_lastCase = m_value;
    emit lastCaseChanged();
    switch (m_value) {
    case 0: emit case0(); break;
    case 1: emit case1(); break;
    case 2: emit case2(); break;
    case 3: emit case3(); break;
    default: m_lastCase = -1; emit lastCaseChanged(); emit caseDefault(); break;
    }
}

void FlowSwitch::setValue(int v) {
    if (m_value == v) return;
    m_value = v;
    emit switchValueChanged();
}

QJsonObject FlowSwitch::saveState() const { return {{"value", m_value}}; }
void FlowSwitch::loadState(const QJsonObject& s) {
    if (s.contains("value")) setValue(s["value"].toInt());
}
