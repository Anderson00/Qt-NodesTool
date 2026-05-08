#include "comparison.h"
#include "behaviours/behaviourregistry.h"
#include <cmath>

REGISTER_BEHAVIOUR(Comparison, "Comparison", "Compares two values: ==, !=, <, >, <=, >=", "logic", 2, 2)

Comparison::Comparison(QObject *parent) : Behaviours(parent)
{
    setWidth(220);
    setHeight(190);
    setContentHeight(190);
    setQmlBodyUrl("qrc:/behaviours/logic/Comparison.qml");
    addInputOutputExclusion({"operationChanged()","valueAChanged()","valueBChanged()","resultChanged()"});
}

QMap<QString, QVariant> Comparison::loadInfos() { return static_infos(); }

QMap<QString, QVariant> Comparison::static_infos() {
    return {{"name","Comparison"},{"type",Behaviours::Type::CPP},{"className","Comparison"},{"desc","Compares two values: ==, !=, <, >, <=, >="},{"inputs_count","2"},{"outputs_count","2"}};
}

int    Comparison::operation() const { return m_operation; }
double Comparison::valueA()    const { return m_a; }
double Comparison::valueB()    const { return m_b; }
bool   Comparison::result()    const { return m_result; }

void Comparison::setA(double a) { m_a = a; emit valueAChanged(); compute(); }
void Comparison::setB(double b) { m_b = b; emit valueBChanged(); compute(); }
void Comparison::setOperation(int op) { if(m_operation!=op){m_operation=op; emit operationChanged(); compute();} }

void Comparison::compute() {
    bool r = false;
    switch(static_cast<Op>(m_operation)) {
    case Equal:        r = qFuzzyCompare(m_a, m_b); break;
    case NotEqual:     r = !qFuzzyCompare(m_a, m_b); break;
    case Less:         r = m_a < m_b; break;
    case Greater:      r = m_a > m_b; break;
    case LessEqual:    r = m_a <= m_b; break;
    case GreaterEqual: r = m_a >= m_b; break;
    }
    m_result = r;
    emit resultChanged();
    emit outputResult(r);
    emit outputString(r ? "true" : "false");
}

QJsonObject Comparison::saveState() const { return {{"operation",m_operation},{"a",m_a},{"b",m_b}}; }
void Comparison::loadState(const QJsonObject& s) {
    if(s.contains("operation")) setOperation(s["operation"].toInt());
    if(s.contains("a")) setA(s["a"].toDouble());
    if(s.contains("b")) setB(s["b"].toDouble());
}
