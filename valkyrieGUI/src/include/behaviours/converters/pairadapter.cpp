#include "pairadapter.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(PairAdapter, "Pair Adapter", "Adapts a (A, B) pair between all int/double type combinations", "converters", 6, 5)

PairAdapter::PairAdapter(QObject *parent) : Behaviours(parent)
{
    this->setWidth(220);
    this->setHeight(180);
    this->setContentHeight(180);
    this->setQmlBodyUrl("qrc:/behaviours/converters/PairAdapter.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setAutoSend(bool)",
        "propAChanged()",
        "propBChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> PairAdapter::loadInfos()
{
    return PairAdapter::static_infos();
}

QMap<QString, QVariant> PairAdapter::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "PairAdapter"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "PairAdapter"},
        {"desc",          "Adapts a pair between int/double type combinations"},
        {"inputs_count",  "6"},
        {"outputs_count", "5"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

double PairAdapter::propA()    const { return m_a; }
double PairAdapter::propB()    const { return m_b; }
bool   PairAdapter::autoSend() const { return m_autoSend; }

// ── Internal helper ───────────────────────────────────────────────────────────

void PairAdapter::setPair(double a, double b) {
    bool changed = false;
    if (!qFuzzyCompare(m_a, a)) { m_a = a; emit propAChanged(); changed = true; }
    if (!qFuzzyCompare(m_b, b)) { m_b = b; emit propBChanged(); changed = true; }
    if (changed && m_autoSend) send();
}

// ── Input setters (input ports) ───────────────────────────────────────────────

void PairAdapter::setDD(double a, double b)           { setPair(a, b); }
void PairAdapter::setID(int a, double b)              { setPair(double(a), b); }
void PairAdapter::setII(int a, int b)                 { setPair(double(a), double(b)); }
void PairAdapter::setDI(double a, int b)              { setPair(a, double(b)); }

void PairAdapter::setInputData(const QVariantList& d) {
    if (d.size() >= 2) setPair(d[0].toDouble(), d[1].toDouble());
    else if (d.size() == 1) setPair(d[0].toDouble(), 0.0);
}

void PairAdapter::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void PairAdapter::trigger() { send(); }

void PairAdapter::send() {
    emit outputDD(m_a, m_b);
    emit outputID(static_cast<int>(m_a), m_b);
    emit outputII(static_cast<int>(m_a), static_cast<int>(m_b));
    emit outputDI(m_a, static_cast<int>(m_b));
    emit outputData({m_a, m_b});
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject PairAdapter::saveState() const {
    QJsonObject s;
    s["a"]         = m_a;
    s["b"]         = m_b;
    s["autoSend"]  = m_autoSend;
    return s;
}

void PairAdapter::loadState(const QJsonObject& s) {
    double a = s.contains("a") ? s["a"].toDouble() : m_a;
    double b = s.contains("b") ? s["b"].toDouble() : m_b;
    setPair(a, b);
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
