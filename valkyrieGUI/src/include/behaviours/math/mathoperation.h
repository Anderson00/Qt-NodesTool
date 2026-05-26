#ifndef MATHOPERATION_H
#define MATHOPERATION_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class MathOperation : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int    operation READ operation WRITE setOperation NOTIFY operationChanged)
    Q_PROPERTY(double valueA    READ valueA    NOTIFY valueAChanged)
    Q_PROPERTY(double valueB    READ valueB    NOTIFY valueBChanged)
    Q_PROPERTY(double result    READ result    NOTIFY resultChanged)

public:
    enum Operation { Add = 0, Subtract, Multiply, Divide, Modulo, Power };
    Q_ENUM(Operation)

    explicit MathOperation(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int    operation() const;
    double valueA()    const;
    double valueB()    const;
    double result()    const;

public slots:
    void setA(double a);
    void setB(double b);
    void setOperation(int op);

signals:
    void outputResult(double result);
    void outputString(QString result);

    void operationChanged();
    void valueAChanged();
    void valueBChanged();
    void resultChanged();

private:
    void compute();

    int    m_operation = Add;
    double m_a = 0.0;
    double m_b = 0.0;
    double m_result = 0.0;
};

#endif // MATHOPERATION_H
