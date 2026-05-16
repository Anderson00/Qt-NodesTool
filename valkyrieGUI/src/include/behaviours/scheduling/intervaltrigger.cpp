#include "intervaltrigger.h"
#include "behaviours/behaviourregistry.h"

#include <QDateTime>

REGISTER_BEHAVIOUR(IntervalTrigger,
    "Interval Trigger",
    "Fire execOut at a configurable days/hours/minutes/seconds interval",
    "scheduling", 1, 2)

IntervalTrigger::IntervalTrigger(QObject *parent)
    : Behaviours(parent)
{
    setWidth(230);
    setHeight(310);
    setContentHeight(310);
    setQmlBodyUrl("qrc:/behaviours/scheduling/IntervalTriggerViewer.qml");

    addInputOutputExclusion(QList<QString>({
        "daysChanged()", "hoursChanged()", "minutesChanged()", "secondsChanged()",
        "runningChanged()", "fireImmediatelyChanged()",
        "nextTriggerInChanged()", "tickCountChanged()"
    }));

    m_execTimer.setSingleShot(false);
    m_countdownTimer.setInterval(1000);
    m_countdownTimer.setSingleShot(false);

    connect(&m_execTimer,      &QTimer::timeout, this, &IntervalTrigger::onExecTimer);
    connect(&m_countdownTimer, &QTimer::timeout, this, &IntervalTrigger::onCountdownTimer);
}

// ── Static info ───────────────────────────────────────────────────────────────

QMap<QString, QVariant> IntervalTrigger::loadInfos()  { return static_infos(); }
QMap<QString, QVariant> IntervalTrigger::static_infos()
{
    return {
        {"name",          "IntervalTrigger"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "IntervalTrigger"},
        {"desc",          "Fire execOut at a configurable interval"},
        {"inputs_count",  "1"},
        {"outputs_count", "2"}
    };
}

// ── Setters ───────────────────────────────────────────────────────────────────

void IntervalTrigger::setDays(int v)
{
    v = qMax(0, v);
    if (m_days != v) { m_days = v; emit daysChanged(); if (m_execTimer.isActive()) restartTimers(); }
}
void IntervalTrigger::setHours(int v)
{
    v = qMax(0, v);
    if (m_hours != v) { m_hours = v; emit hoursChanged(); if (m_execTimer.isActive()) restartTimers(); }
}
void IntervalTrigger::setMinutes(int v)
{
    v = qMax(0, v);
    if (m_minutes != v) { m_minutes = v; emit minutesChanged(); if (m_execTimer.isActive()) restartTimers(); }
}
void IntervalTrigger::setSeconds(int v)
{
    v = qMax(0, v);
    if (m_seconds != v) { m_seconds = v; emit secondsChanged(); if (m_execTimer.isActive()) restartTimers(); }
}
void IntervalTrigger::setFireImmediately(bool v)
{
    if (m_fireImmediately != v) { m_fireImmediately = v; emit fireImmediatelyChanged(); }
}

// ── Controls ──────────────────────────────────────────────────────────────────

void IntervalTrigger::startTrigger()
{
    qint64 ms = totalMs();
    if (ms <= 0) return;

    m_nextFireMs = QDateTime::currentMSecsSinceEpoch() + ms;
    m_execTimer.setInterval(static_cast<int>(qMin(ms, static_cast<qint64>(INT_MAX))));
    m_execTimer.start();
    m_countdownTimer.start();

    emit runningChanged();
    updateCountdown();

    if (m_fireImmediately) trigger();
}

void IntervalTrigger::stopTrigger()
{
    if (m_execTimer.isActive()) {
        m_execTimer.stop();
        m_countdownTimer.stop();
        m_nextTriggerIn = "--:--:--";
        emit runningChanged();
        emit nextTriggerInChanged();
    }
}

void IntervalTrigger::resetCount()
{
    m_tickCount = 0;
    emit tickCountChanged();
}

void IntervalTrigger::trigger()
{
    m_tickCount++;
    emit tickCountChanged();
    emit execOut();
    emit outputTick(m_tickCount);
}

// ── Internal slots ────────────────────────────────────────────────────────────

void IntervalTrigger::onExecTimer()
{
    m_nextFireMs = QDateTime::currentMSecsSinceEpoch() + totalMs();
    trigger();
}

void IntervalTrigger::onCountdownTimer()
{
    updateCountdown();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

qint64 IntervalTrigger::totalMs() const
{
    return (static_cast<qint64>(m_days)    * 86400LL
          + static_cast<qint64>(m_hours)   *  3600LL
          + static_cast<qint64>(m_minutes) *    60LL
          + static_cast<qint64>(m_seconds)) * 1000LL;
}

void IntervalTrigger::updateCountdown()
{
    qint64 remaining = m_nextFireMs - QDateTime::currentMSecsSinceEpoch();
    if (remaining < 0) remaining = 0;

    qint64 totalSec = remaining / 1000;
    int d = static_cast<int>(totalSec / 86400);
    int h = static_cast<int>((totalSec % 86400) / 3600);
    int m = static_cast<int>((totalSec %  3600) /   60);
    int s = static_cast<int>( totalSec %    60);

    QString next;
    if (d > 0)
        next = QString("%1d %2:%3:%4")
               .arg(d)
               .arg(h, 2, 10, QChar('0'))
               .arg(m, 2, 10, QChar('0'))
               .arg(s, 2, 10, QChar('0'));
    else
        next = QString("%1:%2:%3")
               .arg(h, 2, 10, QChar('0'))
               .arg(m, 2, 10, QChar('0'))
               .arg(s, 2, 10, QChar('0'));

    if (next != m_nextTriggerIn) {
        m_nextTriggerIn = next;
        emit nextTriggerInChanged();
    }
}

void IntervalTrigger::restartTimers()
{
    bool wasRunning = m_execTimer.isActive();
    m_execTimer.stop();
    m_countdownTimer.stop();
    if (wasRunning) startTrigger();
}

// ── State persistence ─────────────────────────────────────────────────────────

QJsonObject IntervalTrigger::saveState() const
{
    return {
        {"days",            m_days},
        {"hours",           m_hours},
        {"minutes",         m_minutes},
        {"seconds",         m_seconds},
        {"fireImmediately", m_fireImmediately},
        {"tickCount",       m_tickCount}
    };
}

void IntervalTrigger::loadState(const QJsonObject &s)
{
    if (s.contains("days"))            setDays(s["days"].toInt());
    if (s.contains("hours"))           setHours(s["hours"].toInt());
    if (s.contains("minutes"))         setMinutes(s["minutes"].toInt());
    if (s.contains("seconds"))         setSeconds(s["seconds"].toInt());
    if (s.contains("fireImmediately")) setFireImmediately(s["fireImmediately"].toBool());
    if (s.contains("tickCount"))       { m_tickCount = s["tickCount"].toInt(); emit tickCountChanged(); }
}
