#include "flowbranch.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(FlowBranch, "Flow Branch", "Routes execution based on a boolean condition (If/Else)", "flow", 2, 2)

FlowBranch::FlowBranch(QObject *parent) : Behaviours(parent)
{
    setWidth(220); setHeight(180); setContentHeight(180);
    setQmlBodyUrl("qrc:/behaviours/flow/FlowBranchViewer.qml");
    addInputOutputExclusion({"conditionChanged()","lastPathChanged()"});
}

void FlowBranch::onPinsReady()
{
    // inputs
    setPinTypeForSignature("trigger()",          Connections::FlowType);
    setPinTypeForSignature("setCondition(bool)", Connections::BoolType);
    // outputs
    setPinTypeForSignature("execTrue()",  Connections::FlowType);
    setPinTypeForSignature("execFalse()", Connections::FlowType);
}

QMap<QString, QVariant> FlowBranch::loadInfos() { return static_infos(); }
QMap<QString, QVariant> FlowBranch::static_infos() {
    return {{"name","Flow Branch"},{"type",Behaviours::CPP},{"className","FlowBranch"},
            {"desc","Routes execution based on a boolean condition (If/Else)"},{"inputs_count","2"},{"outputs_count","2"}};
}

void FlowBranch::trigger() {
    if (m_condition) {
        m_lastPath = 1;
        emit lastPathChanged();
        emit execTrue();
    } else {
        m_lastPath = 2;
        emit lastPathChanged();
        emit execFalse();
    }
}

void FlowBranch::setCondition(bool v) {
    if (m_condition == v) return;
    m_condition = v;
    emit conditionChanged();
}

QJsonObject FlowBranch::saveState() const { return {{"condition", m_condition}}; }
void FlowBranch::loadState(const QJsonObject& s) {
    if (s.contains("condition")) setCondition(s["condition"].toBool());
}
