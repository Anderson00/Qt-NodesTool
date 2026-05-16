#include "scriptscheduler.h"
#include "behaviours/behaviourregistry.h"
#include "utils/pythonengine.h"
#include "model/variablemanager.h"

#ifdef slots
#undef slots
#include "utils/croncpp.h"
#define slots Q_SLOTS
#else
#include "utils/croncpp.h"
#endif

#include <QUuid>
#include <QFile>
#include <QJsonArray>

REGISTER_BEHAVIOUR(ScriptScheduler,
    "Script Scheduler",
    "Schedule N Python scripts with individual triggers (Interval, DateTime, Cron, MultiDate)",
    "scheduling", 3, 3)

// ── Constructor ────────────────────────────────────────────────────────────────

ScriptScheduler::ScriptScheduler(QObject *parent)
    : Behaviours(parent)
{
    setWidth(650);
    setHeight(550);
    setContentHeight(550);
    setQmlBodyUrl("qrc:/behaviours/scheduling/ScriptSchedulerViewer.qml");

    addInputOutputExclusion(QList<QString>({"eventsChanged()"}));

    m_globalTimer.setInterval(200);              // 200 ms tick — limits max delay to 200 ms
    m_globalTimer.setTimerType(Qt::PreciseTimer); // avoids CoarseTimer jitter on Windows
    connect(&m_globalTimer, &QTimer::timeout, this, &ScriptScheduler::onGlobalTimer);
    m_globalTimer.start();

    connect(PythonEngine::instance(), &PythonEngine::scriptFinished,
            this, [this](const PythonResult &result) {
                auto eventId = m_taskEventMap.value(result.id);
                if (eventId.isEmpty()) return;
                m_taskEventMap.remove(result.id);
                if (result.success) {
                    QVariantMap outputs = result.outputs;
                    // Merge captured stdout (print() calls) into outputs["stdout"]
                    // so the QML console can display it.
                    if (!result.logs.isEmpty())
                        outputs["stdout"] = result.logs.join("\n");
                    emit eventScriptFinished(eventId, outputs);
                } else {
                    emit eventScriptError(eventId, result.error);
                }
            });
}

// ── Static info ────────────────────────────────────────────────────────────────

QMap<QString, QVariant> ScriptScheduler::loadInfos()  { return static_infos(); }
QMap<QString, QVariant> ScriptScheduler::static_infos()
{
    return {
        {"name",          "ScriptScheduler"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "ScriptScheduler"},
        {"desc",          "Schedule N Python scripts with individual triggers"},
        {"inputs_count",  "3"},
        {"outputs_count", "3"}
    };
}

// ── Scheduler control ──────────────────────────────────────────────────────────

bool ScriptScheduler::isActive() const
{
    return m_globalTimer.isActive();
}

void ScriptScheduler::startScheduler()
{
    if (!m_globalTimer.isActive()) {
        m_globalTimer.start();
        emit activeChanged();
    }
}

void ScriptScheduler::stopScheduler()
{
    if (m_globalTimer.isActive()) {
        m_globalTimer.stop();
        emit activeChanged();
    }
}

// ── Event CRUD ─────────────────────────────────────────────────────────────────

QString ScriptScheduler::addEvent()
{
    ScheduledEvent ev = ScheduledEvent::makeDefault();
    m_events.append(ev);
    emit eventsChanged();
    return ev.id;
}

void ScriptScheduler::removeEvent(const QString &id)
{
    for (int i = 0; i < m_events.size(); ++i) {
        if (m_events[i].id == id) {
            m_events.removeAt(i);
            emit eventsChanged();
            return;
        }
    }
}

QVariantMap ScriptScheduler::getEvent(const QString &id) const
{
    const ScheduledEvent *ev = findEventConst(id);
    if (!ev) return {};
    QStringList dates;
    for (const auto &dt : ev->dateTimes) {
        dates.append(dt.toString(Qt::ISODate));
    }

    return {
        {"id",             ev->id},
        {"name",           ev->name},
        {"enabled",        ev->enabled},
        {"triggerType",    static_cast<int>(ev->triggerType)},
        {"days",           ev->days},
        {"hours",          ev->hours},
        {"minutes",        ev->minutes},
        {"seconds",        ev->seconds},
        {"fireImmediately",ev->fireImmediately},
        {"targetDateTime", ev->targetDateTime.toString(Qt::ISODate)},
        {"repeatMode",     static_cast<int>(ev->repeatMode)},
        {"cronExpression", ev->cronExpression},
        {"multiTimeHour",  ev->multiTimeHour},
        {"multiTimeMinute",ev->multiTimeMinute},
        {"multiTimeSecond",ev->multiTimeSecond},
        {"dateTimes",      dates},
        {"scriptMode",     static_cast<int>(ev->scriptMode)},
        {"scriptCode",     ev->scriptCode},
        {"scriptFile",     ev->scriptFile},
        {"params",         ev->params},
        {"runCount",       ev->runCount},
        {"lastRun",        ev->lastRun.toString("dd/MM/yyyy HH:mm")},
        {"nextRun",        ev->nextRun.toString("dd/MM/yyyy HH:mm")},
        {"nextFireMs",     (qlonglong)ev->nextFireMs}
    };
}

void ScriptScheduler::updateEventField(const QString &id, const QString &field, const QVariant &value)
{
    ScheduledEvent *ev = findEvent(id);
    if (!ev) return;

    if (field == "name")            ev->name           = value.toString();
    else if (field == "enabled")    ev->enabled        = value.toBool();
    else if (field == "triggerType")ev->triggerType    = static_cast<ScheduledEvent::TriggerType>(value.toInt());
    else if (field == "days")       ev->days           = value.toInt();
    else if (field == "hours")      ev->hours          = value.toInt();
    else if (field == "minutes")    ev->minutes        = value.toInt();
    else if (field == "seconds")    ev->seconds        = value.toInt();
    else if (field == "fireImmediately") ev->fireImmediately = value.toBool();
    else if (field == "targetDateTime")
        ev->targetDateTime = QDateTime::fromString(value.toString(), Qt::ISODate);
    else if (field == "repeatMode") ev->repeatMode     = static_cast<ScheduledEvent::RepeatMode>(value.toInt());
    else if (field == "cronExpression") ev->cronExpression = value.toString();
    else if (field == "multiTimeHour")   ev->multiTimeHour   = value.toInt();
    else if (field == "multiTimeMinute") ev->multiTimeMinute = value.toInt();
    else if (field == "multiTimeSecond") ev->multiTimeSecond = value.toInt();
    else if (field == "scriptMode") ev->scriptMode     = static_cast<ScheduledEvent::ScriptMode>(value.toInt());
    else if (field == "scriptCode") ev->scriptCode     = value.toString();
    else if (field == "scriptFile") ev->scriptFile     = value.toString();

    // Any change to interval or trigger type invalidates the cached next-fire timestamp
    if (field == "triggerType" || field == "days"    || field == "hours"  ||
        field == "minutes"     || field == "seconds" || field == "fireImmediately")
        ev->nextFireMs = 0;

    emit eventsChanged();
}

void ScriptScheduler::setEventDates(const QString &id, const QVariantList &isoDateStrings)
{
    ScheduledEvent *ev = findEvent(id);
    if (!ev) return;
    ev->dateTimes.clear();
    for (const QVariant &v : isoDateStrings) {
        QDateTime dt = QDateTime::fromString(v.toString(), Qt::ISODate);
        if (dt.isValid()) ev->dateTimes.append(dt);
    }
    emit eventsChanged();
}

void ScriptScheduler::addEventParam(const QString &id, const QString &key, const QString &value)
{
    ScheduledEvent *ev = findEvent(id);
    if (!ev || key.isEmpty()) return;
    ev->params[key] = value;
    emit eventsChanged();
}

void ScriptScheduler::removeEventParam(const QString &id, const QString &key)
{
    ScheduledEvent *ev = findEvent(id);
    if (!ev) return;
    ev->params.remove(key);
    emit eventsChanged();
}

// ── Manual trigger ─────────────────────────────────────────────────────────────

void ScriptScheduler::triggerEvent(const QString &id)
{
    ScheduledEvent *ev = findEvent(id);
    if (!ev) return;
    runScript(*ev);
}

// ── Global check timer ────────────────────────────────────────────────────────

void ScriptScheduler::onGlobalTimer()
{
    bool scheduleChanged = false;
    for (ScheduledEvent &ev : m_events) {
        if (!ev.enabled) continue;

        qint64 prevNextFireMs = ev.nextFireMs;
        bool due = false;
        switch (ev.triggerType) {
        case ScheduledEvent::Interval:  due = isDueInterval(ev);   break;
        case ScheduledEvent::DateTime:  due = isDueDateTime(ev);   break;
        case ScheduledEvent::Cron:      due = isDueCron(ev);       break;
        case ScheduledEvent::MultiDate: due = isDueMultiDate(ev);  break;
        }

        if (ev.nextFireMs != prevNextFireMs) scheduleChanged = true;
        if (due) runScript(ev); // runScript emits eventsChanged itself
    }
    // Emit only when nextFireMs changed (first tick) and no runScript already did it
    if (scheduleChanged) emit eventsChanged();
}

// ── Due checks ────────────────────────────────────────────────────────────────

bool ScriptScheduler::isDueInterval(ScheduledEvent &ev) const
{
    qint64 ms = (static_cast<qint64>(ev.days)    * 86400LL
               + static_cast<qint64>(ev.hours)   *  3600LL
               + static_cast<qint64>(ev.minutes) *    60LL
               + static_cast<qint64>(ev.seconds)) * 1000LL;
    if (ms <= 0) return false;

    qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (ev.nextFireMs == 0) {
        if (ev.fireImmediately) {
            ev.nextFireMs = now + ms;
            ev.nextRun = QDateTime::fromMSecsSinceEpoch(ev.nextFireMs);
            return true;
        }
        ev.nextFireMs = now + ms;
        ev.nextRun = QDateTime::fromMSecsSinceEpoch(ev.nextFireMs);
        return false;
    }
    if (now >= ev.nextFireMs) {
        // Anchor next fire to the scheduled time, not to 'now', to prevent drift accumulation.
        // If we're more than one period behind (e.g. system was suspended), reset from now
        // to avoid immediate catch-up firing.
        qint64 next = ev.nextFireMs + ms;
        if (next <= now) next = now + ms;
        ev.nextFireMs = next;
        ev.nextRun = QDateTime::fromMSecsSinceEpoch(ev.nextFireMs);
        return true;
    }
    return false;
}

bool ScriptScheduler::isDueDateTime(const ScheduledEvent &ev) const
{
    if (!ev.targetDateTime.isValid()) return false;
    QDateTime now = QDateTime::currentDateTime();

    switch (ev.repeatMode) {
    case ScheduledEvent::OneShot:
        // Fire once when we pass the target; guard with lastRun
        return now >= ev.targetDateTime && ev.lastRun < ev.targetDateTime;
    case ScheduledEvent::Daily: {
        QDateTime todayTarget = ev.targetDateTime;
        todayTarget.setDate(now.date());
        return now >= todayTarget
            && (!ev.lastRun.isValid() || ev.lastRun.date() < now.date())
            && (now.time() >= todayTarget.time());
    }
    case ScheduledEvent::Weekly: {
        if (now.date().dayOfWeek() != ev.targetDateTime.date().dayOfWeek()) return false;
        QDateTime weekTarget = ev.targetDateTime;
        weekTarget.setDate(now.date());
        return now >= weekTarget
            && (!ev.lastRun.isValid() || ev.lastRun.date() < now.date());
    }
    }
    return false;
}

bool ScriptScheduler::isDueCron(const ScheduledEvent &ev) const
{
    if (ev.cronExpression.isEmpty()) return false;

    // Anti double-fire: check minute
    qint64 nowMin = QDateTime::currentDateTime().toMSecsSinceEpoch() / 60000;
    if (ev.lastRun.isValid()) {
        qint64 lastMin = ev.lastRun.toMSecsSinceEpoch() / 60000;
        if (lastMin == nowMin) return false;
    }

    QString expr = ev.cronExpression.trimmed();
    if (expr == "@yearly"  || expr == "@annually") expr = "0 0 1 1 *";
    else if (expr == "@monthly")  expr = "0 0 1 * *";
    else if (expr == "@weekly")   expr = "0 0 * * 0";
    else if (expr == "@daily" || expr == "@midnight") expr = "0 0 * * *";
    else if (expr == "@hourly")   expr = "0 * * * *";

    QString expr6 = "0 " + expr;
    try {
        auto schedule = cron::make_cron(expr6.toStdString());
        // next occurrence from 1 minute ago
        std::time_t past = QDateTime::currentDateTime().addSecs(-60).toSecsSinceEpoch();
        std::time_t next = cron::cron_next(schedule, past);
        if (next == cron::INVALID_TIME) return false;
        QDateTime nextDt = QDateTime::fromSecsSinceEpoch(static_cast<qint64>(next));
        return QDateTime::currentDateTime() >= nextDt;
    } catch (...) {
        return false;
    }
}

bool ScriptScheduler::isDueMultiDate(const ScheduledEvent &ev) const
{
    if (ev.dateTimes.isEmpty()) return false;

    QDateTime now = QDateTime::currentDateTime();
    QDate today = now.date();
    QTime targetTime(ev.multiTimeHour, ev.multiTimeMinute, ev.multiTimeSecond);

    for (const QDateTime &scheduled : ev.dateTimes) {
        if (scheduled.date() != today) continue;
        // Only fire if current time >= target time and we haven't fired today
        if (now.time() >= targetTime) {
            if (!ev.lastRun.isValid() || ev.lastRun.date() < today)
                return true;
        }
    }
    return false;
}

// ── Script execution ──────────────────────────────────────────────────────────

void ScriptScheduler::runScript(ScheduledEvent &ev)
{
    ev.lastRun  = QDateTime::currentDateTime();
    ev.runCount++;
    emit eventsChanged();

    // Build params map for injection into Python
    QVariantMap injected = ev.params;
    injected["event_id"]   = ev.id;
    injected["event_name"] = ev.name;
    injected["run_count"]  = ev.runCount;
    injected["timestamp"]  = ev.lastRun.toString(Qt::ISODate);

    // Resolve script code
    QString code = ev.scriptCode;
    if (ev.scriptMode == ScheduledEvent::File && !ev.scriptFile.isEmpty()) {
        QFile f(ev.scriptFile);
        if (f.open(QIODevice::ReadOnly | QIODevice::Text))
            code = QString::fromUtf8(f.readAll());
    }
    if (code.trimmed().isEmpty()) code = "# (empty script)";

    PythonTask task;
    task.id      = QUuid::createUuid().toString();
    task.script  = code;
    task.inputs  = injected;
    task.timeoutMs = 30000;

    // Inject global variables
    VariableManager *vm = VariableManager::instance();
    for (int i = 0; i < vm->count(); ++i) {
        NodeVariable *v = vm->variableAt(i);
        if (v) task.variables[v->name()] = v->parsedValue();
    }

    m_taskEventMap[task.id] = ev.id;
    PythonEngine::instance()->executeScript(task);

    // Fire signals
    emit eventFired(ev.id, injected);
    emit execOut(ev.id);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ScheduledEvent *ScriptScheduler::findEvent(const QString &id)
{
    for (ScheduledEvent &ev : m_events)
        if (ev.id == id) return &ev;
    return nullptr;
}

const ScheduledEvent *ScriptScheduler::findEventConst(const QString &id) const
{
    for (const ScheduledEvent &ev : m_events)
        if (ev.id == id) return &ev;
    return nullptr;
}

QVariantList ScriptScheduler::eventsAsVariant() const
{
    QVariantList list;
    for (const ScheduledEvent &ev : m_events)
        list.append(getEvent(ev.id));
    return list;
}

// ── State persistence ─────────────────────────────────────────────────────────

QJsonObject ScriptScheduler::saveState() const
{
    QJsonArray arr;
    for (const ScheduledEvent &ev : m_events)
        arr.append(ev.toJson());
    QJsonObject obj;
    obj["events"] = arr;
    obj["active"] = m_globalTimer.isActive();
    return obj;
}

void ScriptScheduler::loadState(const QJsonObject &state)
{
    m_events.clear();
    QJsonArray arr = state["events"].toArray();
    for (const auto &v : arr)
        m_events.append(ScheduledEvent::fromJson(v.toObject()));
    emit eventsChanged();

    // Restore active state (default: true for backwards compatibility)
    bool wasActive = state.value("active").toBool(true);
    if (wasActive && !m_globalTimer.isActive())
        m_globalTimer.start();
    else if (!wasActive && m_globalTimer.isActive())
        m_globalTimer.stop();
    emit activeChanged();
}
