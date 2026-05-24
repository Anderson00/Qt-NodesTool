#include "flowend.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(FlowEnd, "Flow End", "Terminal node that marks the end of an execution path", "flow", 1, 0)

FlowEnd::FlowEnd(QObject *parent) : Behaviours(parent)
{
    setWidth(200); setHeight(130); setContentHeight(130);
    setQmlBodyUrl("qrc:/behaviours/flow/FlowEndViewer.qml");
    addInputOutputExclusion({"triggered()","hitCountChanged()"});
}

QMap<QString, QVariant> FlowEnd::loadInfos() { return static_infos(); }
QMap<QString, QVariant> FlowEnd::static_infos() {
    return {{"name","Flow End"},{"type",Behaviours::CPP},{"className","FlowEnd"},
            {"desc","Terminal node that marks the end of an execution path"},{"inputs_count","1"},{"outputs_count","0"}};
}

void FlowEnd::trigger() {
    ++m_hits;
    emit hitCountChanged();
    emit triggered();
}

void FlowEnd::reset() {
    m_hits = 0;
    emit hitCountChanged();
}

QJsonObject FlowEnd::saveState() const { return {{"hitCount", m_hits}}; }
void FlowEnd::loadState(const QJsonObject& s) {
    if (s.contains("hitCount")) { m_hits = s["hitCount"].toInt(); emit hitCountChanged(); }
}
