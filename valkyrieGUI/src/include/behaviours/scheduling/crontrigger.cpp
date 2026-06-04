#include "crontrigger.h"
#include "behaviours/behaviourregistry.h"

// Wrap croncpp in a try/catch-friendly context.
// croncpp uses exceptions for invalid expressions.
#ifdef slots
#undef slots
#include "utils/croncpp.h"
#define slots Q_SLOTS
#else
#include "utils/croncpp.h"
#endif

#include <QRegularExpression>

REGISTER_BEHAVIOUR(CronTrigger,
    "Cron Trigger",
    "Fire execOut based on a full cron expression",
    "scheduling", 1, 1)

CronTrigger::CronTrigger(QObject *parent)
    : Behaviours(parent)
{
    setWidth(280);
    setHeight(260);
    setContentHeight(260);
    setQmlBodyUrl("qrc:/behaviours/scheduling/CronTriggerViewer.qml");

    addInputOutputExclusion(QList<QString>({
        "cronExpressionChanged()", "enabledChanged()", "isValidChanged()",
        "descriptionChanged()", "nextOccurrenceChanged()",
        "lastOccurrenceChanged()", "fireCountChanged()"
    }));

    m_checkTimer.setInterval(30000); // 30 s
    connect(&m_checkTimer, &QTimer::timeout, this, &CronTrigger::onCheckTimer);

    parseExpression();
}

// ── Static info ───────────────────────────────────────────────────────────────

void CronTrigger::onPinsReady()
{
    // inputs
    setPinTypeForSignature("setCronExpression(QString)", Connections::StringType);
    // outputs
    setPinTypeForSignature("execOut()", Connections::FlowType);
}

QMap<QString, QVariant> CronTrigger::loadInfos()  { return static_infos(); }
QMap<QString, QVariant> CronTrigger::static_infos()
{
    return {
        {"name",          "CronTrigger"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "CronTrigger"},
        {"desc",          "Fire execOut based on a full cron expression"},
        {"inputs_count",  "1"},
        {"outputs_count", "1"}
    };
}

// ── Setters ───────────────────────────────────────────────────────────────────

void CronTrigger::setCronExpression(const QString &expr)
{
    if (m_cronExpression != expr) {
        m_cronExpression = expr;
        emit cronExpressionChanged();
        parseExpression();
    }
}

void CronTrigger::setEnabled(bool v)
{
    if (m_enabled != v) {
        m_enabled = v;
        emit enabledChanged();
        if (m_enabled && m_isValid) {
            m_checkTimer.start();
            updateNextOccurrence();
        } else {
            m_checkTimer.stop();
        }
    }
}

void CronTrigger::testFire()
{
    m_fireCount++;
    m_lastOccurrence = QDateTime::currentDateTime().toString("ddd dd/MM HH:mm");
    emit fireCountChanged();
    emit lastOccurrenceChanged();
    emit execOut();
}

// ── Timer check ───────────────────────────────────────────────────────────────

void CronTrigger::onCheckTimer()
{
    if (!m_enabled || !m_isValid) return;

    QDateTime now = QDateTime::currentDateTime();
    // Round to minute boundary
    qint64 nowMin = now.toMSecsSinceEpoch() / 60000;

    if (m_lastFiredMinute == nowMin) return; // already fired this minute

    QDateTime next = computeNext();
    if (!next.isValid()) return;

    // Fire if we're past the scheduled time (within this minute window)
    if (now >= next) {
        m_lastFiredMinute = nowMin;
        m_fireCount++;
        m_lastOccurrence = now.toString("ddd dd/MM HH:mm");
        emit fireCountChanged();
        emit lastOccurrenceChanged();
        emit execOut();
        updateNextOccurrence();
    }
}

// ── Parsing & helpers ─────────────────────────────────────────────────────────

void CronTrigger::parseExpression()
{
    // croncpp uses 6-field (with seconds) format by default.
    // We support 5-field standard cron; prepend "0 " to convert.
    QString expr = m_cronExpression.trimmed();

    // Handle predefined macros
    if (expr == "@yearly" || expr == "@annually") expr = "0 0 1 1 *";
    else if (expr == "@monthly")  expr = "0 0 1 * *";
    else if (expr == "@weekly")   expr = "0 0 * * 0";
    else if (expr == "@daily" || expr == "@midnight") expr = "0 0 * * *";
    else if (expr == "@hourly")   expr = "0 * * * *";

    // Convert 5-field to 6-field (croncpp expects seconds as first field)
    QString expr6 = "0 " + expr;

    bool valid = false;
    try {
        auto schedule = cron::make_cron(expr6.toStdString());
        (void)schedule;
        valid = true;
    } catch (...) {
        valid = false;
    }

    if (valid != m_isValid) {
        m_isValid = valid;
        emit isValidChanged();
    }

    updateDescription();
    updateNextOccurrence();
}

void CronTrigger::updateDescription()
{
    m_description = m_isValid ? buildDescription() : "Invalid expression";
    emit descriptionChanged();
}

void CronTrigger::updateNextOccurrence()
{
    if (!m_isValid) {
        m_nextOccurrence = "—";
        emit nextOccurrenceChanged();
        return;
    }
    QDateTime next = computeNext();
    m_nextOccurrence = next.isValid()
        ? next.toString("ddd dd/MM/yyyy HH:mm")
        : "—";
    emit nextOccurrenceChanged();
}

QDateTime CronTrigger::computeNext() const
{
    if (!m_isValid) return {};

    QString expr = m_cronExpression.trimmed();
    if (expr == "@yearly"  || expr == "@annually") expr = "0 0 1 1 *";
    else if (expr == "@monthly")  expr = "0 0 1 * *";
    else if (expr == "@weekly")   expr = "0 0 * * 0";
    else if (expr == "@daily" || expr == "@midnight") expr = "0 0 * * *";
    else if (expr == "@hourly")   expr = "0 * * * *";

    QString expr6 = "0 " + expr;

    try {
        auto schedule = cron::make_cron(expr6.toStdString());
        std::time_t now = std::time(nullptr) + 1; // 1 second ahead to skip current
        std::time_t next = cron::cron_next(schedule, now);
        if (next == cron::INVALID_TIME) return {};
        return QDateTime::fromSecsSinceEpoch(static_cast<qint64>(next));
    } catch (...) {
        return {};
    }
}

// ── Human-readable description ────────────────────────────────────────────────

QString CronTrigger::buildDescription() const
{
    QString expr = m_cronExpression.trimmed();

    // Macro shortcuts
    if (expr == "@yearly"  || expr == "@annually") return "Uma vez por ano (1° Jan 00:00)";
    if (expr == "@monthly")                        return "Uma vez por mês (dia 1, 00:00)";
    if (expr == "@weekly")                         return "Uma vez por semana (Dom 00:00)";
    if (expr == "@daily"   || expr == "@midnight") return "Todo dia às 00:00";
    if (expr == "@hourly")                         return "A cada hora";

    QStringList parts = expr.split(' ', Qt::SkipEmptyParts);
    if (parts.size() < 5) return "Expressão inválida";

    QString minField  = parts[0];
    QString hourField = parts[1];
    QString domField  = parts[2];
    QString monField  = parts[3];
    QString dowField  = parts[4];

    // Build time description
    QString timeDesc;
    if (minField == "0" && hourField == "0")       timeDesc = "às 00:00";
    else if (hourField == "*" && minField == "0")  timeDesc = "a cada hora (minuto 0)";
    else if (hourField == "*")                     timeDesc = QString("a cada hora no minuto %1").arg(minField);
    else if (minField == "*")                      timeDesc = QString("todo minuto da hora %1").arg(hourField);
    else if (!hourField.contains('*') && !minField.contains('*'))
        timeDesc = QString("às %1:%2").arg(hourField.toInt(), 2, 10, QChar('0'))
                                      .arg(minField.toInt(),  2, 10, QChar('0'));
    else timeDesc = QString("min=%1 hora=%2").arg(minField).arg(hourField);

    // Day-of-week
    static const QStringList dowNames = {"Dom","Seg","Ter","Qua","Qui","Sex","Sáb"};
    QString dowDesc;
    if (dowField != "*" && dowField != "?") {
        QStringList items;
        for (const QString &part : dowField.split(',')) {
            if (part.contains('-')) {
                QStringList range = part.split('-');
                if (range.size() == 2) {
                    int from = range[0].toInt();
                    int to   = range[1].toInt();
                    if (from >= 0 && to <= 6 && from <= to) {
                        QStringList days;
                        for (int i = from; i <= to; ++i) days << dowNames[i];
                        items << days.join("-");
                    } else {
                        items << part;
                    }
                }
            } else {
                bool ok; int d = part.toInt(&ok);
                items << (ok && d >= 0 && d <= 6 ? dowNames[d] : part);
            }
        }
        dowDesc = items.join(", ");
    }

    // Day-of-month
    QString domDesc;
    if (domField != "*" && domField != "?")
        domDesc = QString("dia %1").arg(domField);

    // Month
    static const QStringList monNames = {"","Jan","Fev","Mar","Abr","Mai","Jun",
                                         "Jul","Ago","Set","Out","Nov","Dez"};
    QString monDesc;
    if (monField != "*") {
        bool ok; int m = monField.toInt(&ok);
        monDesc = (ok && m >= 1 && m <= 12) ? monNames[m] : monField;
    }

    // Assemble
    QString result;
    if (!dowDesc.isEmpty())
        result = dowDesc + " " + timeDesc;
    else if (!domDesc.isEmpty())
        result = domDesc + (monDesc.isEmpty() ? "" : " de " + monDesc) + " " + timeDesc;
    else if (!monDesc.isEmpty())
        result = "Todo " + monDesc + " " + timeDesc;
    else
        result = "Todo dia " + timeDesc;

    return result;
}

// ── State persistence ─────────────────────────────────────────────────────────

QJsonObject CronTrigger::saveState() const
{
    return {
        {"cronExpression", m_cronExpression},
        {"enabled",        m_enabled},
        {"fireCount",      m_fireCount},
        {"lastOccurrence", m_lastOccurrence}
    };
}

void CronTrigger::loadState(const QJsonObject &s)
{
    if (s.contains("cronExpression")) setCronExpression(s["cronExpression"].toString());
    if (s.contains("fireCount"))      { m_fireCount = s["fireCount"].toInt(); emit fireCountChanged(); }
    if (s.contains("lastOccurrence")) { m_lastOccurrence = s["lastOccurrence"].toString(); emit lastOccurrenceChanged(); }
    if (s.contains("enabled"))        setEnabled(s["enabled"].toBool());
}
