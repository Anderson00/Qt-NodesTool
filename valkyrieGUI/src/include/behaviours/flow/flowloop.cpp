#include "flowloop.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(FlowLoop, "Flow Loop", "Repeats an execution path N times then fires completed", "flow", 3, 3)

FlowLoop::FlowLoop(QObject *parent) : Behaviours(parent)
{
    setWidth(220); setHeight(200); setContentHeight(200);
    setQmlBodyUrl("qrc:/behaviours/flow/FlowLoopViewer.qml");
    addInputOutputExclusion({"iterationsChanged()","currentIterationChanged()","isRunningChanged()"});

    m_timer.setSingleShot(true);
    m_timer.setInterval(0); // yield to event loop between iterations
    connect(&m_timer, &QTimer::timeout, this, &FlowLoop::onTick);
}

FlowLoop::~FlowLoop() { m_timer.stop(); }

void FlowLoop::onPinsReady()
{
    // inputs
    setPinTypeForSignature("trigger()",          Connections::FlowType);
    setPinTypeForSignature("setIterations(int)", Connections::IntType);
    setPinTypeForSignature("breakLoop()",        Connections::FlowType);
    // outputs
    setPinTypeForSignature("body()",             Connections::FlowType);
    setPinTypeForSignature("completed()",        Connections::FlowType);
    setPinTypeForSignature("outputIndex(int)",   Connections::IntType);
}

QMap<QString, QVariant> FlowLoop::loadInfos() { return static_infos(); }
QMap<QString, QVariant> FlowLoop::static_infos() {
    return {{"name","Flow Loop"},{"type",Behaviours::CPP},{"className","FlowLoop"},
            {"desc","Repeats an execution path N times then fires completed"},{"inputs_count","3"},{"outputs_count","3"}};
}

void FlowLoop::trigger() {
    if (m_running) return;
    m_break   = false;
    m_current = 0;
    m_running = true;
    emit isRunningChanged();
    m_timer.start();
}

void FlowLoop::setIterations(int v) {
    m_iterations = qMax(1, qMin(v, 1000));
    emit iterationsChanged();
}

void FlowLoop::breakLoop() {
    m_break = true;
}

void FlowLoop::onTick() {
    if (m_break || m_current >= m_iterations) {
        m_running = false;
        m_current = 0;
        emit isRunningChanged();
        emit currentIterationChanged();
        emit completed();
        return;
    }
    emit outputIndex(m_current);
    emit body();
    ++m_current;
    emit currentIterationChanged();
    m_timer.start(); // schedule next tick
}

QJsonObject FlowLoop::saveState() const { return {{"iterations", m_iterations}}; }
void FlowLoop::loadState(const QJsonObject& s) {
    if (s.contains("iterations")) setIterations(s["iterations"].toInt());
}
