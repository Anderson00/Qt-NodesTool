#include "flowmerge.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(FlowMerge, "Flow Merge", "Passes any of three execution inputs to a single output", "flow", 3, 1)

FlowMerge::FlowMerge(QObject *parent) : Behaviours(parent)
{
    setWidth(200); setHeight(150); setContentHeight(150);
    setQmlBodyUrl("qrc:/behaviours/flow/FlowMergeViewer.qml");
    addInputOutputExclusion({"lastSourceChanged()","mergeCountChanged()"});
}

void FlowMerge::onPinsReady()
{
    // inputs
    setPinTypeForSignature("triggerA()", Connections::FlowType);
    setPinTypeForSignature("triggerB()", Connections::FlowType);
    setPinTypeForSignature("triggerC()", Connections::FlowType);
    // outputs
    setPinTypeForSignature("execOut()", Connections::FlowType);
}

QMap<QString, QVariant> FlowMerge::loadInfos() { return static_infos(); }
QMap<QString, QVariant> FlowMerge::static_infos() {
    return {{"name","Flow Merge"},{"type",Behaviours::CPP},{"className","FlowMerge"},
            {"desc","Passes any of three execution inputs to a single output"},{"inputs_count","3"},{"outputs_count","1"}};
}

void FlowMerge::triggerA() { fire("A"); }
void FlowMerge::triggerB() { fire("B"); }
void FlowMerge::triggerC() { fire("C"); }

void FlowMerge::fire(const QString& source) {
    m_lastSource = source;
    ++m_count;
    emit lastSourceChanged();
    emit mergeCountChanged();
    emit execOut();
}

QJsonObject FlowMerge::saveState() const { return {{"count", m_count}}; }
void FlowMerge::loadState(const QJsonObject& s) {
    if (s.contains("count")) { m_count = s["count"].toInt(); emit mergeCountChanged(); }
}
