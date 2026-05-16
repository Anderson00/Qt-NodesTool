#ifndef SCRIPTSCHEDULER_H
#define SCRIPTSCHEDULER_H

#include <QObject>
#include <QTimer>
#include <QDateTime>
#include <QVariantList>
#include <QJsonObject>
#include <QJsonArray>
#include <behaviours/behaviours.h>
#include "scheduledscript.h"

class ScriptScheduler : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QVariantList events     READ eventsAsVariant  NOTIFY eventsChanged)
    Q_PROPERTY(int          eventCount READ eventCount       NOTIFY eventsChanged)
    Q_PROPERTY(bool         active     READ isActive         NOTIFY activeChanged)

public:
    explicit ScriptScheduler(QObject *parent = nullptr);
    ~ScriptScheduler() override = default;

    bool isActive() const;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject &state) override;

    QVariantList eventsAsVariant() const;
    int          eventCount() const { return m_events.size(); }

public slots:
    // ── Scheduler control ─────────────────────────────────────────────────────
    void startScheduler();
    void stopScheduler();

    // ── Event CRUD ────────────────────────────────────────────────────────────
    QString     addEvent();
    void        removeEvent(const QString &id);
    QVariantMap getEvent(const QString &id) const;
    void        updateEventField(const QString &id, const QString &field, const QVariant &value);

    // Bulk update from QML
    void        setEventDates(const QString &id, const QVariantList &isoDateStrings);
    void        addEventParam(const QString &id, const QString &key, const QString &value);
    void        removeEventParam(const QString &id, const QString &key);

    // ── Manual fire ───────────────────────────────────────────────────────────
    void triggerEvent(const QString &id);

signals:
    void activeChanged();

    // Primary signals for inter-node connection
    void eventFired(const QString &eventId, const QVariantMap &params);
    void eventScriptFinished(const QString &eventId, const QVariantMap &outputs);
    void eventScriptError(const QString &eventId, const QString &error);
    void execOut(const QString &eventId);

    void eventsChanged();

private slots:
    void onGlobalTimer();

private:
    ScheduledEvent *findEvent(const QString &id);
    const ScheduledEvent *findEventConst(const QString &id) const;

    bool isDueInterval(ScheduledEvent &ev) const;
    bool isDueDateTime(const ScheduledEvent &ev) const;
    bool isDueCron(const ScheduledEvent &ev) const;
    bool isDueMultiDate(const ScheduledEvent &ev) const;

    void runScript(ScheduledEvent &ev);

    QList<ScheduledEvent> m_events;
    QTimer                m_globalTimer;   // 30 s check loop

    // Map task-uuid → event-id for async script result routing
    QMap<QString, QString> m_taskEventMap;
};

#endif // SCRIPTSCHEDULER_H
