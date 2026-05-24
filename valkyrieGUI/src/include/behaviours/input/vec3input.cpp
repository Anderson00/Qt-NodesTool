#include "vec3input.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(Vec3Input, "Vec3 Input", "Sends a 3D vector (X, Y, Z) with color-coded axes to connected nodes", "input", 1, 3)

Vec3Input::Vec3Input(QObject *parent) : Behaviours(parent)
{
    this->setWidth(260);
    this->setHeight(260);
    this->setContentHeight(260);
    this->setQmlBodyUrl("qrc:/behaviours/input/Vec3Input.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setVecX(double)",
        "setVecY(double)",
        "setVecZ(double)",
        "setAutoSend(bool)",
        "vecXChanged()",
        "vecYChanged()",
        "vecZChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> Vec3Input::loadInfos()
{
    return Vec3Input::static_infos();
}

QMap<QString, QVariant> Vec3Input::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "Vec3Input"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "Vec3Input"},
        {"desc",          "Sends a 3D vector with color-coded axes"},
        {"inputs_count",  "1"},
        {"outputs_count", "3"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

double Vec3Input::vecX()     const { return m_vecX; }
double Vec3Input::vecY()     const { return m_vecY; }
double Vec3Input::vecZ()     const { return m_vecZ; }
bool   Vec3Input::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void Vec3Input::setVecX(double x) {
    if (!qFuzzyCompare(m_vecX, x)) {
        m_vecX = x;
        emit vecXChanged();
        if (m_autoSend) send();
    }
}

void Vec3Input::setVecY(double y) {
    if (!qFuzzyCompare(m_vecY, y)) {
        m_vecY = y;
        emit vecYChanged();
        if (m_autoSend) send();
    }
}

void Vec3Input::setVecZ(double z) {
    if (!qFuzzyCompare(m_vecZ, z)) {
        m_vecZ = z;
        emit vecZChanged();
        if (m_autoSend) send();
    }
}

void Vec3Input::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void Vec3Input::trigger() { send(); }

void Vec3Input::send() {
    emit outputXYZ(m_vecX, m_vecY, m_vecZ);
    emit outputString(QString("(%1, %2, %3)").arg(m_vecX).arg(m_vecY).arg(m_vecZ));
    emit outputData({m_vecX, m_vecY, m_vecZ});
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject Vec3Input::saveState() const {
    QJsonObject s;
    s["vecX"]     = m_vecX;
    s["vecY"]     = m_vecY;
    s["vecZ"]     = m_vecZ;
    s["autoSend"] = m_autoSend;
    return s;
}

void Vec3Input::loadState(const QJsonObject& s) {
    if (s.contains("vecX"))     setVecX(s["vecX"].toDouble());
    if (s.contains("vecY"))     setVecY(s["vecY"].toDouble());
    if (s.contains("vecZ"))     setVecZ(s["vecZ"].toDouble());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
