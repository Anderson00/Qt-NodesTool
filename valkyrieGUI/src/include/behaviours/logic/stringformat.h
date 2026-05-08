#ifndef STRINGFORMAT_H
#define STRINGFORMAT_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class StringFormat : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString templateStr  READ templateStr  WRITE setTemplate  NOTIFY templateChanged)
    Q_PROPERTY(QString resultStr    READ resultStr    NOTIFY resultChanged)
    Q_PROPERTY(int     precision    READ precision    WRITE setPrecision NOTIFY precisionChanged)

public:
    explicit StringFormat(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString templateStr() const;
    QString resultStr()   const;
    int     precision()   const;

public slots:
    void setA(double a);
    void setB(double b);
    void setC(double c);
    void setTemplate(const QString& tmpl);
    void setPrecision(int digits);

signals:
    void outputString(QString result);

    void templateChanged();
    void resultChanged();
    void precisionChanged();

private:
    void compute();

    QString m_template  = "A={A}, B={B}, C={C}";
    double  m_a = 0.0;
    double  m_b = 0.0;
    double  m_c = 0.0;
    QString m_result;
    int     m_precision = 2;
};

#endif // STRINGFORMAT_H
