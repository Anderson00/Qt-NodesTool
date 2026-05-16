#include "flowsequence.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(FlowSequence, "Flow Sequence", "Fires three execution outputs in order", "flow", 1, 3)

FlowSequence::FlowSequence(QObject *parent) : Behaviours(parent)
{
    setWidth(200); setHeight(160); setContentHeight(160);
    setQmlBodyUrl("qrc:/behaviours/flow/FlowSequenceViewer.qml");
    addInputOutputExclusion({"currentStepChanged()","isRunningChanged()"});
}

QMap<QString, QVariant> FlowSequence::loadInfos() { return static_infos(); }
QMap<QString, QVariant> FlowSequence::static_infos() {
    return {{"name","Flow Sequence"},{"type",Behaviours::CPP},{"className","FlowSequence"},
            {"desc","Fires three execution outputs in order"},{"inputs_count","1"},{"outputs_count","3"}};
}

void FlowSequence::trigger() {
    if (m_running) return;
    m_running = true;
    emit isRunningChanged();

    // Fire each step synchronously — Qt signal dispatch is synchronous within
    // the same thread, so step1 chain finishes before step2 fires.
    m_step = 1; emit currentStepChanged(); emit step1();
    m_step = 2; emit currentStepChanged(); emit step2();
    m_step = 3; emit currentStepChanged(); emit step3();

    m_step = 0; m_running = false;
    emit currentStepChanged();
    emit isRunningChanged();
}
