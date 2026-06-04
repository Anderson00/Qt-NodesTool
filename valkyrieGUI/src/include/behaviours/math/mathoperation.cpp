#include "mathoperation.h"
#include "behaviours/behaviourregistry.h"
#include <cmath>

REGISTER_BEHAVIOUR(MathOperation, "Math Operation", "Binary arithmetic operation: +, -, ×, ÷, %, pow", "math", 2, 2)

MathOperation::MathOperation(QObject *parent) : Behaviours(parent)
{
    this->setWidth(240);
    this->setHeight(200);
    this->setContentHeight(200);
    this->setQmlBodyUrl("qrc:/behaviours/math/MathOperation.qml");
    this->addInputOutputExclusion(QList<QString>({
        "operationChanged()",
        "valueAChanged()",
        "valueBChanged()",
        "resultChanged()"
    }));
}

QMap<QString, QVariant> MathOperation::loadInfos()
{
    return MathOperation::static_infos();
}

QMap<QString, QVariant> MathOperation::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "MathOperation"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "MathOperation"},
        {"desc",          "Binary arithmetic: +, -, ×, ÷, %, pow"},
        {"inputs_count",  "2"},
        {"outputs_count", "2"}
    });
}

void MathOperation::onPinsReady()
{
    // inputs
    setPinTypeForSignature("setA(double)", Connections::DoubleType);
    setPinTypeForSignature("setB(double)", Connections::DoubleType);
    // outputs
    setPinTypeForSignature("outputResult(double)",  Connections::DoubleType);
    setPinTypeForSignature("outputString(QString)", Connections::StringType);
}

// ── Accessors ────────────────────────────────────────────────────────────────

int    MathOperation::operation() const { return m_operation; }
double MathOperation::valueA()    const { return m_a; }
double MathOperation::valueB()    const { return m_b; }
double MathOperation::result()    const { return m_result; }

// ── Slots ────────────────────────────────────────────────────────────────────

void MathOperation::setA(double a) {
    m_a = a;
    emit valueAChanged();
    compute();
}

void MathOperation::setB(double b) {
    m_b = b;
    emit valueBChanged();
    compute();
}

void MathOperation::setOperation(int op) {
    if (m_operation != op) {
        m_operation = op;
        emit operationChanged();
        compute();
    }
}

// ── Compute ──────────────────────────────────────────────────────────────────

void MathOperation::compute() {
    double r = 0.0;
    switch (static_cast<Operation>(m_operation)) {
    case Add:      r = m_a + m_b; break;
    case Subtract: r = m_a - m_b; break;
    case Multiply: r = m_a * m_b; break;
    case Divide:   r = (m_b != 0.0) ? m_a / m_b : std::numeric_limits<double>::quiet_NaN(); break;
    case Modulo:   r = (m_b != 0.0) ? std::fmod(m_a, m_b) : std::numeric_limits<double>::quiet_NaN(); break;
    case Power:    r = std::pow(m_a, m_b); break;
    }
    m_result = r;
    emit resultChanged();
    emit outputResult(r);
    emit outputString(QString::number(r));
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject MathOperation::saveState() const {
    QJsonObject s;
    s["operation"] = m_operation;
    s["a"]         = m_a;
    s["b"]         = m_b;
    return s;
}

void MathOperation::loadState(const QJsonObject& s) {
    if (s.contains("operation")) setOperation(s["operation"].toInt());
    if (s.contains("a"))         setA(s["a"].toDouble());
    if (s.contains("b"))         setB(s["b"].toDouble());
}
