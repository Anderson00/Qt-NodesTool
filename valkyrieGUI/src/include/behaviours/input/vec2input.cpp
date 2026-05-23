#include "vec2input.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(Vec2Input, "Vec2 Input", "Sends a 2D vector (X, Y) with graphical arrow preview to connected nodes", "input", 1, 2)

Vec2Input::Vec2Input(QObject *parent) : Behaviours(parent)
{
    this->setWidth(260);
    this->setHeight(240);
    this->setContentHeight(240);
    this->setQmlBodyUrl("qrc:/behaviours/input/Vec2Input.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setVecX(double)",
        "setVecY(double)",
        "setAutoSend(bool)",
        "vecXChanged()",
        "vecYChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> Vec2Input::loadInfos()
{
    return Vec2Input::static_infos();
}

QMap<QString, QVariant> Vec2Input::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "Vec2Input"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "Vec2Input"},
        {"desc",          "Sends a 2D vector with graphical preview"},
        {"inputs_count",  "1"},
        {"outputs_count", "2"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

double Vec2Input::vecX()     const { return m_vecX; }
double Vec2Input::vecY()     const { return m_vecY; }
bool   Vec2Input::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void Vec2Input::setVecX(double x) {
    if (!qFuzzyCompare(m_vecX, x)) {
        m_vecX = x;
        emit vecXChanged();
        if (m_autoSend) send();
    }
}

void Vec2Input::setVecY(double y) {
    if (!qFuzzyCompare(m_vecY, y)) {
        m_vecY = y;
        emit vecYChanged();
        if (m_autoSend) send();
    }
}

void Vec2Input::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void Vec2Input::trigger() { send(); }

void Vec2Input::send() {
    emit outputXY(m_vecX, m_vecY);
    emit outputString(QString("(%1, %2)").arg(m_vecX).arg(m_vecY));
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject Vec2Input::saveState() const {
    QJsonObject s;
    s["vecX"]     = m_vecX;
    s["vecY"]     = m_vecY;
    s["autoSend"] = m_autoSend;
    return s;
}

void Vec2Input::loadState(const QJsonObject& s) {
    if (s.contains("vecX"))     setVecX(s["vecX"].toDouble());
    if (s.contains("vecY"))     setVecY(s["vecY"].toDouble());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
