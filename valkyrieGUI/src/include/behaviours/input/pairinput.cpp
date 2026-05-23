#include "pairinput.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(PairInput, "Pair Input", "Sends an (X, Y) data point to connected nodes", "input", 1, 1)

PairInput::PairInput(QObject *parent) : Behaviours(parent)
{
    this->setWidth(260);
    this->setHeight(200);
    this->setContentHeight(200);
    this->setQmlBodyUrl("qrc:/behaviours/input/PairInput.qml");
    this->addInputOutputExclusion(QList<QString>({
        "send()",
        "setXValue(double)",
        "setYValue(double)",
        "setAutoSend(bool)",
        "xValueChanged()",
        "yValueChanged()",
        "autoSendChanged()"
    }));
}

QMap<QString, QVariant> PairInput::loadInfos()
{
    return PairInput::static_infos();
}

QMap<QString, QVariant> PairInput::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "PairInput"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "PairInput"},
        {"desc",          "Sends an (X, Y) data point to connected nodes"},
        {"inputs_count",  "1"},
        {"outputs_count", "1"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

double PairInput::xValue()   const { return m_xValue; }
double PairInput::yValue()   const { return m_yValue; }
bool   PairInput::autoSend() const { return m_autoSend; }

// ── Setters ──────────────────────────────────────────────────────────────────

void PairInput::setXValue(double x) {
    if (!qFuzzyCompare(m_xValue, x)) {
        m_xValue = x;
        emit xValueChanged();
        if (m_autoSend) send();
    }
}

void PairInput::setYValue(double y) {
    if (!qFuzzyCompare(m_yValue, y)) {
        m_yValue = y;
        emit yValueChanged();
        if (m_autoSend) send();
    }
}

void PairInput::setAutoSend(bool enabled) {
    if (m_autoSend != enabled) {
        m_autoSend = enabled;
        emit autoSendChanged();
    }
}

// ── Core ─────────────────────────────────────────────────────────────────────

void PairInput::trigger() { send(); }

void PairInput::send() {
    emit outputXY(m_xValue, m_yValue);
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject PairInput::saveState() const {
    QJsonObject s;
    s["xValue"]   = m_xValue;
    s["yValue"]   = m_yValue;
    s["autoSend"] = m_autoSend;
    return s;
}

void PairInput::loadState(const QJsonObject& s) {
    if (s.contains("xValue"))   setXValue(s["xValue"].toDouble());
    if (s.contains("yValue"))   setYValue(s["yValue"].toDouble());
    if (s.contains("autoSend")) setAutoSend(s["autoSend"].toBool());
}
