#include "ratelimiter.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(RateLimiter, "Rate Limiter", "Throttle or debounce high-frequency signal inputs", "transform", 2, 1)

RateLimiter::RateLimiter(QObject *parent) : Behaviours(parent)
{
    setWidth(280);
    setHeight(200);
    setContentHeight(200);
    setQmlBodyUrl("qrc:/behaviours/transform/RateLimiter.qml");
    addInputOutputExclusion(QList<QString>({
        "internalPassed(QVariant)",
        "internalDropped()",
        "modeChanged()",
        "intervalMsChanged()",
        "droppedCountChanged()",
        "passedCountChanged()"
    }));

    m_debounceTimer.setSingleShot(true);
    connect(&m_debounceTimer, &QTimer::timeout, this, [this]() {
        emit passed(m_pendingValue);
        emit internalPassed(m_pendingValue);
        ++m_passedCount;
        emit passedCountChanged();
    });
}

void RateLimiter::onPinsReady()
{
    // inputs
    setPinTypeForSignature("push(QVariant)", Connections::AnyType);
    // outputs
    setPinTypeForSignature("passed(QVariant)", Connections::AnyType);
}

QMap<QString, QVariant> RateLimiter::loadInfos() { return RateLimiter::static_infos(); }

QMap<QString, QVariant> RateLimiter::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "RateLimiter"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "RateLimiter"},
        {"desc",          "Throttle or debounce high-frequency signal inputs"},
        {"inputs_count",  "2"},
        {"outputs_count", "1"}
    });
}

QString RateLimiter::mode()         const { return m_mode; }
int     RateLimiter::intervalMs()   const { return m_intervalMs; }
int     RateLimiter::droppedCount() const { return m_droppedCount; }
int     RateLimiter::passedCount()  const { return m_passedCount; }

void RateLimiter::setMode(QString mode)
{
    if (m_mode == mode) return;
    m_mode = mode;
    m_debounceTimer.stop();
    m_elapsedStarted = false;
    emit modeChanged();
}

void RateLimiter::setIntervalMs(int ms)
{
    if (ms < 1) ms = 1;
    if (m_intervalMs == ms) return;
    m_intervalMs = ms;
    emit intervalMsChanged();
}

void RateLimiter::push(QVariant value)
{
    if (m_mode == "throttle") {
        bool allow = false;
        if (!m_elapsedStarted) {
            allow = true;
        } else if (m_elapsed.elapsed() >= m_intervalMs) {
            allow = true;
        }

        if (allow) {
            m_elapsed.start();
            m_elapsedStarted = true;
            emit passed(value);
            emit internalPassed(value);
            ++m_passedCount;
            emit passedCountChanged();
        } else {
            ++m_droppedCount;
            emit droppedCountChanged();
            emit internalDropped();
        }
    } else {
        // debounce
        m_pendingValue = value;
        m_debounceTimer.start(m_intervalMs);
        ++m_droppedCount;
        emit droppedCountChanged();
        emit internalDropped();
    }
}

QJsonObject RateLimiter::saveState() const
{
    return {{"mode", m_mode}, {"intervalMs", m_intervalMs}};
}

void RateLimiter::loadState(const QJsonObject &state)
{
    if (state.contains("mode"))       setMode(state["mode"].toString());
    if (state.contains("intervalMs")) setIntervalMs(state["intervalMs"].toInt());
}
