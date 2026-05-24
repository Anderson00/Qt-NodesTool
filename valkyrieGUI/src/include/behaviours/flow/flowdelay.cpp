#include "flowdelay.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(FlowDelay, "Flow Delay", "Waits a given number of milliseconds before passing execution", "flow", 2, 1)

FlowDelay::FlowDelay(QObject *parent) : Behaviours(parent)
{
    setWidth(220); setHeight(160); setContentHeight(160);
    setQmlBodyUrl("qrc:/behaviours/flow/FlowDelayViewer.qml");
    addInputOutputExclusion({"delayMsChanged()","isWaitingChanged()"});

    m_timer.setSingleShot(true);
    connect(&m_timer, &QTimer::timeout, this, &FlowDelay::onTimeout);
}

QMap<QString, QVariant> FlowDelay::loadInfos() { return static_infos(); }
QMap<QString, QVariant> FlowDelay::static_infos() {
    return {{"name","Flow Delay"},{"type",Behaviours::CPP},{"className","FlowDelay"},
            {"desc","Waits a given number of milliseconds before passing execution"},{"inputs_count","2"},{"outputs_count","1"}};
}

void FlowDelay::trigger() {
    m_timer.stop();
    m_waiting = true;
    emit isWaitingChanged();
    m_timer.start(m_delayMs);
}

void FlowDelay::setDelayMs(int ms) {
    m_delayMs = qMax(0, ms);
    emit delayMsChanged();
}

void FlowDelay::onTimeout() {
    m_waiting = false;
    emit isWaitingChanged();
    emit execOut();
}

QJsonObject FlowDelay::saveState() const { return {{"delayMs", m_delayMs}}; }
void FlowDelay::loadState(const QJsonObject& s) {
    if (s.contains("delayMs")) setDelayMs(s["delayMs"].toInt());
}
