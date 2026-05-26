#include "expressioneval.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(ExpressionEvaluator,
    "Expression Evaluator",
    "Evaluate a custom math/JS expression with up to 4 inputs (a,b,c,d)",
    "math", 4, 2)

ExpressionEvaluator::ExpressionEvaluator(QObject *parent)
    : Behaviours(parent)
{
    setWidth(280);
    setHeight(220);
    setContentHeight(220);
    setQmlBodyUrl("qrc:/behaviours/math/ExpressionEvaluator.qml");
    addInputOutputExclusion(QList<QString>({
        "expressionChanged()",
        "valueAChanged()", "valueBChanged()",
        "valueCChanged()", "valueDChanged()",
        "resultChanged()", "errorMsgChanged()"
    }));

    // Seed the JS engine with Math.* helpers and named input vars
    m_engine.evaluate("var a=0,b=0,c=0,d=0;");
}

void ExpressionEvaluator::onPinsReady()
{
    // inputs
    setPinTypeForSignature("setA(double)", Connections::DoubleType);
    setPinTypeForSignature("setB(double)", Connections::DoubleType);
    setPinTypeForSignature("setC(double)", Connections::DoubleType);
    setPinTypeForSignature("setD(double)", Connections::DoubleType);
    // outputs
    setPinTypeForSignature("outputResult(double)", Connections::DoubleType);
    setPinTypeForSignature("outputString(QString)", Connections::StringType);
}

QMap<QString, QVariant> ExpressionEvaluator::loadInfos()
{
    return ExpressionEvaluator::static_infos();
}

QMap<QString, QVariant> ExpressionEvaluator::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "ExpressionEvaluator"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "ExpressionEvaluator"},
        {"desc",          "Evaluate a JS/Math expression with 4 inputs"},
        {"inputs_count",  "4"},
        {"outputs_count", "2"}
    });
}

// ── Slots ────────────────────────────────────────────────────────────────────

void ExpressionEvaluator::setExpression(const QString& expr) {
    if (m_expression == expr) return;
    m_expression = expr;
    emit expressionChanged();
    evaluate();
}

void ExpressionEvaluator::setA(double v) { m_a = v; emit valueAChanged(); evaluate(); }
void ExpressionEvaluator::setB(double v) { m_b = v; emit valueBChanged(); evaluate(); }
void ExpressionEvaluator::setC(double v) { m_c = v; emit valueCChanged(); evaluate(); }
void ExpressionEvaluator::setD(double v) { m_d = v; emit valueDChanged(); evaluate(); }

// ── Evaluate ─────────────────────────────────────────────────────────────────

void ExpressionEvaluator::evaluate() {
    if (m_expression.trimmed().isEmpty()) return;

    // Inject current input values into JS scope
    m_engine.globalObject().setProperty("a", m_a);
    m_engine.globalObject().setProperty("b", m_b);
    m_engine.globalObject().setProperty("c", m_c);
    m_engine.globalObject().setProperty("d", m_d);

    QJSValue val = m_engine.evaluate(m_expression);
    if (val.isError()) {
        m_error = val.toString();
        emit errorMsgChanged();
        return;
    }

    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorMsgChanged();
    }

    m_result = val.toNumber();
    emit resultChanged();
    emit outputResult(m_result);
    emit outputString(QString::number(m_result));
}

// ── State ────────────────────────────────────────────────────────────────────

QJsonObject ExpressionEvaluator::saveState() const {
    QJsonObject s;
    s["expression"] = m_expression;
    s["a"] = m_a; s["b"] = m_b; s["c"] = m_c; s["d"] = m_d;
    return s;
}

void ExpressionEvaluator::loadState(const QJsonObject& s) {
    if (s.contains("expression")) setExpression(s["expression"].toString());
    if (s.contains("a")) setA(s["a"].toDouble());
    if (s.contains("b")) setB(s["b"].toDouble());
    if (s.contains("c")) setC(s["c"].toDouble());
    if (s.contains("d")) setD(s["d"].toDouble());
}
