#include "mathfunction.h"
#include "behaviours/behaviourregistry.h"
#include <cmath>

REGISTER_BEHAVIOUR(MathFunction, "Math Function", "Unary math function: sin, cos, abs, sqrt, log, exp, etc.", "math", 1, 2)

MathFunction::MathFunction(QObject *parent) : Behaviours(parent)
{
    this->setWidth(220);
    this->setHeight(190);
    this->setContentHeight(190);
    this->setQmlBodyUrl("qrc:/behaviours/math/MathFunction.qml");
    this->addInputOutputExclusion(QList<QString>({
        "functionChanged()",
        "inputValueChanged()",
        "resultChanged()"
    }));
}

QMap<QString, QVariant> MathFunction::loadInfos()
{
    return MathFunction::static_infos();
}

QMap<QString, QVariant> MathFunction::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "MathFunction"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "MathFunction"},
        {"desc",          "Unary math function: sin, cos, abs, sqrt, log, exp, etc."},
        {"inputs_count",  "1"},
        {"outputs_count", "2"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

int    MathFunction::function()   const { return m_function; }
double MathFunction::inputValue() const { return m_inputValue; }
double MathFunction::result()     const { return m_result; }

// ── Slots ────────────────────────────────────────────────────────────────────

void MathFunction::setInput(double value) {
    m_inputValue = value;
    emit inputValueChanged();
    compute();
}

void MathFunction::setFunction(int func) {
    if (m_function != func) {
        m_function = func;
        emit functionChanged();
        compute();
    }
}

// ── Compute ──────────────────────────────────────────────────────────────────

void MathFunction::compute() {
    double r = 0.0;
    switch (static_cast<Function>(m_function)) {
    case Sin:   r = std::sin(m_inputValue);   break;
    case Cos:   r = std::cos(m_inputValue);   break;
    case Tan:   r = std::tan(m_inputValue);   break;
    case Abs:   r = std::abs(m_inputValue);   break;
    case Sqrt:  r = std::sqrt(m_inputValue);  break;
    case Log:   r = std::log(m_inputValue);   break;
    case Log10: r = std::log10(m_inputValue); break;
    case Exp:   r = std::exp(m_inputValue);   break;
    case Floor: r = std::floor(m_inputValue); break;
    case Ceil:  r = std::ceil(m_inputValue);  break;
    case Round: r = std::round(m_inputValue); break;
    }
    m_result = r;
    emit resultChanged();
    emit outputResult(r);
    emit outputString(QString::number(r));
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject MathFunction::saveState() const {
    return { {"function", m_function} };
}

void MathFunction::loadState(const QJsonObject& s) {
    if (s.contains("function")) setFunction(s["function"].toInt());
}
