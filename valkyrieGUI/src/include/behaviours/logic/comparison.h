#ifndef COMPARISON_H
#define COMPARISON_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class Comparison : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int    operation READ operation WRITE setOperation NOTIFY operationChanged)
    Q_PROPERTY(double valueA   READ valueA    NOTIFY valueAChanged)
    Q_PROPERTY(double valueB   READ valueB    NOTIFY valueBChanged)
    Q_PROPERTY(bool   result   READ result    NOTIFY resultChanged)

public:
    enum Op { Equal = 0, NotEqual, Less, Greater, LessEqual, GreaterEqual };
    Q_ENUM(Op)

    explicit Comparison(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int    operation() const;
    double valueA()    const;
    double valueB()    const;
    bool   result()    const;

public slots:
    void setA(double a);
    void setB(double b);
    void setOperation(int op);

signals:
    void outputResult(bool result);
    void outputString(QString result);

    void operationChanged();
    void valueAChanged();
    void valueBChanged();
    void resultChanged();

private:
    void compute();

    int    m_operation = Equal;
    double m_a = 0.0;
    double m_b = 0.0;
    bool   m_result = true;
};

#endif // COMPARISON_H
