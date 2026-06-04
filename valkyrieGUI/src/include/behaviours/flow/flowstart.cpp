#include "flowstart.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(FlowStart, "Flow Start", "Entry point of an execution flow", "flow", 1, 1)

FlowStart::FlowStart(QObject *parent) : Behaviours(parent)
{
    setWidth(200); setHeight(160); setContentHeight(160);
    setQmlBodyUrl("qrc:/behaviours/flow/FlowStartViewer.qml");
    addInputOutputExclusion({"autoStartChanged()","runCountChanged()"});
}

void FlowStart::onPinsReady()
{
    // inputs
    setPinTypeForSignature("trigger()", Connections::FlowType);
    // outputs
    setPinTypeForSignature("execOut()", Connections::FlowType);
}

QMap<QString, QVariant> FlowStart::loadInfos() { return static_infos(); }
QMap<QString, QVariant> FlowStart::static_infos() {
    return {{"name","Flow Start"},{"type",Behaviours::CPP},{"className","FlowStart"},
            {"desc","Entry point of an execution flow"},{"inputs_count","1"},{"outputs_count","1"}};
}

void FlowStart::trigger() {
    ++m_runCount;
    emit runCountChanged();
    emit execOut();
}

void FlowStart::setAutoStart(bool v) {
    if (m_autoStart == v) return;
    m_autoStart = v;
    emit autoStartChanged();
    if (m_autoStart) trigger();
}

QJsonObject FlowStart::saveState() const { return {{"autoStart", m_autoStart}, {"runCount", m_runCount}}; }
void FlowStart::loadState(const QJsonObject& s) {
    if (s.contains("autoStart")) setAutoStart(s["autoStart"].toBool());
    if (s.contains("runCount"))  { m_runCount = s["runCount"].toInt(); emit runCountChanged(); }
}
