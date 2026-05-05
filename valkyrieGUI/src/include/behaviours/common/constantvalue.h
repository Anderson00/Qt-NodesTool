#ifndef CONSTANTVALUE_H
#define CONSTANTVALUE_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class ConstantValue : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double  numericValue READ numericValue WRITE setNumericValue NOTIFY numericValueChanged)
    Q_PROPERTY(QString textValue    READ textValue    WRITE setTextValue    NOTIFY textValueChanged)
    Q_PROPERTY(bool    boolValue    READ boolValue    WRITE setBoolValue    NOTIFY boolValueChanged)
    Q_PROPERTY(int     mode         READ mode         WRITE setMode         NOTIFY modeChanged)

public:
    enum Mode { Numeric = 0, Text, Boolean };
    Q_ENUM(Mode)

    explicit ConstantValue(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double  numericValue() const;
    QString textValue()    const;
    bool    boolValue()    const;
    int     mode()         const;

public slots:
    void send();
    void setNumericValue(double value);
    void setTextValue(const QString& value);
    void setBoolValue(bool value);
    void setMode(int mode);

signals:
    void outputValue(double value);
    void outputString(QString value);
    void outputBool(bool value);
    void outputInt(int value);

    void numericValueChanged();
    void textValueChanged();
    void boolValueChanged();
    void modeChanged();

private:
    double  m_numericValue = 0.0;
    QString m_textValue;
    bool    m_boolValue = false;
    int     m_mode      = Numeric;
};

#endif // CONSTANTVALUE_H
