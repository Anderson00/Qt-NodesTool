#include "timernode.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(TimerNode, "Timer", "Periodic pulse generator with configurable interval", "common", 4, 3)

TimerNode::TimerNode(QObject *parent) : Behaviours(parent)
{
    this->setWidth(220);
    this->setHeight(180);
    this->setContentHeight(180);
    this->setQmlBodyUrl("qrc:/behaviours/common/TimerNode.qml");
    this->addInputOutputExclusion(QList<QString>({
        "trigger()",
        "resetCount()",
        "intervalChanged()",
        "runningChanged()",
        "tickCountChanged()"
    }));

    m_timer.setTimerType(Qt::PreciseTimer);
    QObject::connect(&m_timer, &QTimer::timeout, this, [this]() {
        m_tickCount++;
        emit tickCountChanged();
        emit triggered();
        emit outputTick(m_tickCount);
        emit outputValue(static_cast<double>(m_tickCount));
    });
}

QMap<QString, QVariant> TimerNode::loadInfos()
{
    return TimerNode::static_infos();
}

QMap<QString, QVariant> TimerNode::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "TimerNode"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "TimerNode"},
        {"desc",          "Periodic pulse generator with configurable interval"},
        {"inputs_count",  "4"},
        {"outputs_count", "3"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

int  TimerNode::interval()  const { return m_interval; }
bool TimerNode::running()   const { return m_timer.isActive(); }
int  TimerNode::tickCount() const { return m_tickCount; }

// ── Slots ────────────────────────────────────────────────────────────────────

void TimerNode::setInterval(int ms) {
    ms = qMax(1, ms);
    if (m_interval != ms) {
        m_interval = ms;
        m_timer.setInterval(ms);
        emit intervalChanged();
    }
}

void TimerNode::startTimer() {
    if (!m_timer.isActive()) {
        m_timer.start(m_interval);
        emit runningChanged();
    }
}

void TimerNode::stopTimer() {
    if (m_timer.isActive()) {
        m_timer.stop();
        emit runningChanged();
    }
}

void TimerNode::trigger() {
    m_tickCount++;
    emit tickCountChanged();
    emit triggered();
    emit outputTick(m_tickCount);
    emit outputValue(static_cast<double>(m_tickCount));
}

void TimerNode::resetCount() {
    m_tickCount = 0;
    emit tickCountChanged();
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject TimerNode::saveState() const {
    return { {"interval", m_interval} };
}

void TimerNode::loadState(const QJsonObject& state) {
    if (state.contains("interval"))
        setInterval(state["interval"].toInt(1000));
}
