#ifndef MATHFUNCTION_H
#define MATHFUNCTION_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class MathFunction : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int    function   READ function   WRITE setFunction   NOTIFY functionChanged)
    Q_PROPERTY(double inputValue READ inputValue NOTIFY inputValueChanged)
    Q_PROPERTY(double result     READ result     NOTIFY resultChanged)

public:
    enum Function {
        Sin = 0, Cos, Tan, Abs, Sqrt, Log, Log10, Exp, Floor, Ceil, Round
    };
    Q_ENUM(Function)

    explicit MathFunction(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int    function()   const;
    double inputValue() const;
    double result()     const;

public slots:
    void setInput(double value);
    void setFunction(int func);

signals:
    void outputResult(double result);
    void outputString(QString result);

    void functionChanged();
    void inputValueChanged();
    void resultChanged();

private:
    void compute();

    int    m_function   = Sin;
    double m_inputValue = 0.0;
    double m_result     = 0.0;
};

#endif // MATHFUNCTION_H
