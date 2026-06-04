#ifndef EXPRESSIONEVAL_H
#define EXPRESSIONEVAL_H

#include <QObject>
#include <QJsonObject>
#include <QJSEngine>
#include <behaviours/behaviours.h>

// ─────────────────────────────────────────────────────────────────────────────
// ExpressionEvaluator — evaluates a user-defined JS/math expression using
// QJSEngine (no Python runtime required). Supports up to 4 named inputs
// (a, b, c, d) plus all Math.* functions.
//
// Example expressions:
//   a * Math.sin(b) + c * 3.14
//   Math.abs(a - b) / (c + 0.001)
// ─────────────────────────────────────────────────────────────────────────────
class ExpressionEvaluator : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString expression READ expression  WRITE setExpression NOTIFY expressionChanged)
    Q_PROPERTY(double  valueA     READ valueA      NOTIFY valueAChanged)
    Q_PROPERTY(double  valueB     READ valueB      NOTIFY valueBChanged)
    Q_PROPERTY(double  valueC     READ valueC      NOTIFY valueCChanged)
    Q_PROPERTY(double  valueD     READ valueD      NOTIFY valueDChanged)
    Q_PROPERTY(double  result     READ result      NOTIFY resultChanged)
    Q_PROPERTY(QString errorMsg   READ errorMsg    NOTIFY errorMsgChanged)
    Q_PROPERTY(bool    hasError   READ hasError    NOTIFY errorMsgChanged)

public:
    explicit ExpressionEvaluator(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString expression() const { return m_expression; }
    double  valueA()     const { return m_a; }
    double  valueB()     const { return m_b; }
    double  valueC()     const { return m_c; }
    double  valueD()     const { return m_d; }
    double  result()     const { return m_result; }
    QString errorMsg()   const { return m_error; }
    bool    hasError()   const { return !m_error.isEmpty(); }

public slots:
    void setExpression(const QString& expr);
    void setA(double v);
    void setB(double v);
    void setC(double v);
    void setD(double v);

signals:
    void outputResult(double result);
    void outputString(QString result);

    void expressionChanged();
    void valueAChanged();
    void valueBChanged();
    void valueCChanged();
    void valueDChanged();
    void resultChanged();
    void errorMsgChanged();

private:
    void evaluate();

    QJSEngine m_engine;
    QString   m_expression = "a + b";
    double    m_a = 0.0, m_b = 0.0, m_c = 0.0, m_d = 0.0;
    double    m_result = 0.0;
    QString   m_error;
};

#endif // EXPRESSIONEVAL_H
