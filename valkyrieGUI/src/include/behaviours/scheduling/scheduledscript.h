#ifndef SCHEDULEDSCRIPT_H
#define SCHEDULEDSCRIPT_H

#include <QString>
#include <QDateTime>
#include <QVariantMap>
#include <QList>
#include <QJsonObject>
#include <QJsonArray>
#include <QUuid>

// ─── ScheduledEvent ──────────────────────────────────────────────────────────
// Plain data object representing one scheduled event inside a ScriptScheduler.
// Not a QObject — serialised/deserialised via QJsonObject helpers.

struct ScheduledEvent
{
    // ── Identity ──────────────────────────────────────────────────────────────
    QString id;          // UUID
    QString name;        // human label
    bool    enabled = true;

    // ── Trigger type ──────────────────────────────────────────────────────────
    enum TriggerType { Interval = 0, DateTime, Cron, MultiDate };
    TriggerType triggerType = Interval;

    // Interval fields
    int     days    = 0;
    int     hours   = 1;
    int     minutes = 0;
    int     seconds = 0;
    bool    fireImmediately = false;

    // DateTime fields
    QDateTime targetDateTime;
    enum RepeatMode { OneShot = 0, Daily, Weekly };
    RepeatMode repeatMode = OneShot;

    // Cron fields
    QString cronExpression = "0 * * * *";

    // MultiDate fields — list of specific datetimes
    QList<QDateTime> dateTimes;
    int     multiTimeHour   = 9;
    int     multiTimeMinute = 0;
    int     multiTimeSecond = 0;

    // ── Script ────────────────────────────────────────────────────────────────
    enum ScriptMode { Inline = 0, File };
    ScriptMode scriptMode = Inline;
    QString scriptCode;    // inline python
    QString scriptFile;    // path to .py file

    // ── Extra params injected into script context ─────────────────────────────
    QVariantMap params;    // user-defined key/value

    // ── Runtime state ─────────────────────────────────────────────────────────
    QDateTime lastRun;
    QDateTime nextRun;
    int       runCount = 0;

    // ── Interval runtime state ────────────────────────────────────────────────
    qint64 nextFireMs = 0;  // epoch ms of next Interval fire

    // ─── Serialization ────────────────────────────────────────────────────────
    static ScheduledEvent fromJson(const QJsonObject &obj);
    QJsonObject toJson() const;

    static ScheduledEvent makeDefault() {
        ScheduledEvent e;
        e.id   = QUuid::createUuid().toString(QUuid::WithoutBraces);
        e.name = "New Event";
        e.scriptCode =
            "# event_id, event_name and params are available\n"
            "print('Event fired:', event_id)\n";
        return e;
    }
};

// ─── JSON helpers ─────────────────────────────────────────────────────────────

inline QJsonObject ScheduledEvent::toJson() const
{
    QJsonObject o;
    o["id"]          = id;
    o["name"]        = name;
    o["enabled"]     = enabled;
    o["triggerType"] = static_cast<int>(triggerType);
    o["days"]        = days;
    o["hours"]       = hours;
    o["minutes"]     = minutes;
    o["seconds"]     = seconds;
    o["fireImmediately"] = fireImmediately;
    o["targetDateTime"]  = targetDateTime.toString(Qt::ISODate);
    o["repeatMode"]      = static_cast<int>(repeatMode);
    o["cronExpression"]  = cronExpression;
    o["multiTimeHour"]   = multiTimeHour;
    o["multiTimeMinute"] = multiTimeMinute;
    o["multiTimeSecond"] = multiTimeSecond;
    o["scriptMode"]      = static_cast<int>(scriptMode);
    o["scriptCode"]      = scriptCode;
    o["scriptFile"]      = scriptFile;
    o["runCount"]        = runCount;
    o["lastRun"]         = lastRun.toString(Qt::ISODate);

    QJsonArray dts;
    for (const QDateTime &dt : dateTimes)
        dts.append(dt.toString(Qt::ISODate));
    o["dateTimes"] = dts;

    QJsonObject ps;
    for (auto it = params.constBegin(); it != params.constEnd(); ++it)
        ps[it.key()] = it.value().toString();
    o["params"] = ps;

    return o;
}

inline ScheduledEvent ScheduledEvent::fromJson(const QJsonObject &obj)
{
    ScheduledEvent e;
    e.id          = obj["id"].toString(QUuid::createUuid().toString(QUuid::WithoutBraces));
    e.name        = obj["name"].toString("Event");
    e.enabled     = obj["enabled"].toBool(true);
    e.triggerType = static_cast<TriggerType>(obj["triggerType"].toInt(0));
    e.days        = obj["days"].toInt(0);
    e.hours       = obj["hours"].toInt(1);
    e.minutes     = obj["minutes"].toInt(0);
    e.seconds     = obj["seconds"].toInt(0);
    e.fireImmediately = obj["fireImmediately"].toBool(false);
    e.targetDateTime  = QDateTime::fromString(obj["targetDateTime"].toString(), Qt::ISODate);
    e.repeatMode      = static_cast<RepeatMode>(obj["repeatMode"].toInt(0));
    e.cronExpression  = obj["cronExpression"].toString("0 * * * *");
    e.multiTimeHour   = obj["multiTimeHour"].toInt(9);
    e.multiTimeMinute = obj["multiTimeMinute"].toInt(0);
    e.multiTimeSecond = obj["multiTimeSecond"].toInt(0);
    e.scriptMode      = static_cast<ScriptMode>(obj["scriptMode"].toInt(0));
    e.scriptCode      = obj["scriptCode"].toString();
    e.scriptFile      = obj["scriptFile"].toString();
    e.runCount        = obj["runCount"].toInt(0);
    e.lastRun         = QDateTime::fromString(obj["lastRun"].toString(), Qt::ISODate);

    QJsonArray dts = obj["dateTimes"].toArray();
    for (const auto &v : dts)
        e.dateTimes.append(QDateTime::fromString(v.toString(), Qt::ISODate));

    QJsonObject ps = obj["params"].toObject();
    for (auto it = ps.constBegin(); it != ps.constEnd(); ++it)
        e.params[it.key()] = it.value().toString();

    return e;
}

#endif // SCHEDULEDSCRIPT_H
