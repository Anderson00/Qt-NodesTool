#include "counter.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(Counter, "Counter", "Simple increment/decrement counter with step control", "common", 4, 2)

Counter::Counter(QObject *parent) : Behaviours(parent)
{
    this->setWidth(200);
    this->setHeight(170);
    this->setContentHeight(170);
    this->setQmlBodyUrl("qrc:/behaviours/common/Counter.qml");
    this->addInputOutputExclusion(QList<QString>({
        "countChanged()",
        "stepChanged()"
    }));
}

QMap<QString, QVariant> Counter::loadInfos()
{
    return Counter::static_infos();
}

QMap<QString, QVariant> Counter::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "Counter"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "Counter"},
        {"desc",          "Simple increment/decrement counter with step control"},
        {"inputs_count",  "4"},
        {"outputs_count", "2"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

int Counter::count() const { return m_count; }
int Counter::step()  const { return m_step; }

// ── Slots ────────────────────────────────────────────────────────────────────

void Counter::increment() {
    m_count += m_step;
    emit countChanged();
    emitAll();
}

void Counter::decrement() {
    m_count -= m_step;
    emit countChanged();
    emitAll();
}

void Counter::reset() {
    m_count = 0;
    emit countChanged();
    emitAll();
}

void Counter::setValue(int value) {
    m_count = value;
    emit countChanged();
    emitAll();
}

void Counter::setStep(int step) {
    if (m_step != step) {
        m_step = qMax(1, step);
        emit stepChanged();
    }
}

void Counter::emitAll() {
    emit outputCount(m_count);
    emit outputValue(static_cast<double>(m_count));
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject Counter::saveState() const {
    QJsonObject s;
    s["count"] = m_count;
    s["step"]  = m_step;
    return s;
}

void Counter::loadState(const QJsonObject& s) {
    if (s.contains("step"))  setStep(s["step"].toInt(1));
    if (s.contains("count")) setValue(s["count"].toInt(0));
}
