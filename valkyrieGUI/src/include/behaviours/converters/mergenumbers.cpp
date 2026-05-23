#include "mergenumbers.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(MergeNumbers, "Merge Numbers", "Combines two separate numeric inputs (A, B) into multi-type pair outputs", "converters", 3, 4)

MergeNumbers::MergeNumbers(QObject *parent) : Behaviours(parent)
{
    this->setWidth(220);
    this->setHeight(200);
    this->setContentHeight(200);
    this->setQmlBodyUrl("qrc:/behaviours/converters/MergeNumbers.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setAutoSend(bool)",
        "aChanged()",
        "bChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> MergeNumbers::loadInfos()
{
    return MergeNumbers::static_infos();
}

QMap<QString, QVariant> MergeNumbers::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "MergeNumbers"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "MergeNumbers"},
        {"desc",          "Combines two separate numeric inputs into pair outputs"},
        {"inputs_count",  "3"},
        {"outputs_count", "4"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

double MergeNumbers::a()        const { return m_a; }
double MergeNumbers::b()        const { return m_b; }
bool   MergeNumbers::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void MergeNumbers::setA(double v) {
    if (!qFuzzyCompare(m_a, v)) {
        m_a = v;
        emit aChanged();
        if (m_autoSend) send();
    }
}

void MergeNumbers::setB(double v) {
    if (!qFuzzyCompare(m_b, v)) {
        m_b = v;
        emit bChanged();
        if (m_autoSend) send();
    }
}

void MergeNumbers::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void MergeNumbers::trigger() { send(); }

void MergeNumbers::send() {
    emit outputDD(m_a, m_b);
    emit outputID(static_cast<int>(m_a), m_b);
    emit outputII(static_cast<int>(m_a), static_cast<int>(m_b));
    emit outputData({m_a, m_b});
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject MergeNumbers::saveState() const {
    QJsonObject s;
    s["a"]        = m_a;
    s["b"]        = m_b;
    s["autoSend"] = m_autoSend;
    return s;
}

void MergeNumbers::loadState(const QJsonObject& s) {
    if (s.contains("a"))        setA(s["a"].toDouble());
    if (s.contains("b"))        setB(s["b"].toDouble());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
