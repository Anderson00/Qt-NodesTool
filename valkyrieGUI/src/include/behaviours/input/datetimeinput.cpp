#include "datetimeinput.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(DateTimeInput, "DateTime Input", "Sends a formatted date/time string or Unix timestamp to connected nodes", "input", 1, 2)

DateTimeInput::DateTimeInput(QObject *parent) : Behaviours(parent)
{
    m_dateTime = QDateTime::currentDateTime();

    this->setWidth(280);
    this->setHeight(340);
    this->setContentHeight(340);
    this->setQmlBodyUrl("qrc:/behaviours/input/DateTimeInput.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setDate(int,int,int)",
        "setTime(int,int,int)",
        "setFormat(QString)",
        "setAutoSend(bool)",
        "dateStrChanged()",
        "formatChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> DateTimeInput::loadInfos()
{
    return DateTimeInput::static_infos();
}

QMap<QString, QVariant> DateTimeInput::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "DateTimeInput"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "DateTimeInput"},
        {"desc",          "Sends a formatted date/time or Unix timestamp"},
        {"inputs_count",  "1"},
        {"outputs_count", "2"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QString DateTimeInput::dateStr()  const { return m_dateTime.toString(m_format); }
QString DateTimeInput::format()   const { return m_format; }
bool    DateTimeInput::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void DateTimeInput::setDate(int year, int month, int day) {
    QDate d(year, month, day);
    if (d.isValid() && m_dateTime.date() != d) {
        m_dateTime.setDate(d);
        emit dateStrChanged();
        if (m_autoSend) send();
    }
}

void DateTimeInput::setTime(int hour, int minute, int second) {
    QTime t(hour, minute, second);
    if (t.isValid() && m_dateTime.time() != t) {
        m_dateTime.setTime(t);
        emit dateStrChanged();
        if (m_autoSend) send();
    }
}

void DateTimeInput::setFormat(const QString& fmt) {
    if (m_format != fmt && !fmt.isEmpty()) {
        m_format = fmt;
        emit formatChanged();
        emit dateStrChanged();
    }
}

void DateTimeInput::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void DateTimeInput::trigger() { send(); }

void DateTimeInput::send() {
    emit outputString(m_dateTime.toString(m_format));
    emit outputTimestamp(static_cast<int>(m_dateTime.toSecsSinceEpoch()));
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject DateTimeInput::saveState() const {
    QJsonObject s;
    s["timestamp"] = static_cast<int>(m_dateTime.toSecsSinceEpoch());
    s["format"]    = m_format;
    s["autoSend"]  = m_autoSend;
    return s;
}

void DateTimeInput::loadState(const QJsonObject& s) {
    if (s.contains("format"))    setFormat(s["format"].toString());
    if (s.contains("timestamp")) {
        m_dateTime = QDateTime::fromSecsSinceEpoch(s["timestamp"].toInt());
        emit dateStrChanged();
    }
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
