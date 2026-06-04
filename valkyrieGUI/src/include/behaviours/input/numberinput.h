#ifndef NUMBERINPUT_H
#define NUMBERINPUT_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class NumberInput : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double value    READ value    WRITE setValue    NOTIFY valueChanged)
    Q_PROPERTY(bool   autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)
    Q_PROPERTY(double stepSize READ stepSize WRITE setStepSize NOTIFY stepSizeChanged)
    Q_PROPERTY(double minValue READ minValue WRITE setMinValue NOTIFY minValueChanged)
    Q_PROPERTY(double maxValue READ maxValue WRITE setMaxValue NOTIFY maxValueChanged)

public:
    explicit NumberInput(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double value()    const;
    bool   autoSend() const;
    double stepSize() const;
    double minValue() const;
    double maxValue() const;

public slots:
    void send();
    void trigger();                    // INPUT PORT — aciona send() via conexão
    void setValue(double v);
    void setAutoSend(bool enabled);
    void setStepSize(double step);
    void setMinValue(double min);
    void setMaxValue(double max);

signals:
    void outputValue(double value);     // OUTPUT PORT — double
    void outputInt(int value);          // OUTPUT PORT — int
    void outputBool(bool value);        // OUTPUT PORT — bool (value != 0)
    void outputString(QString value);   // OUTPUT PORT — string
    void outputData(QVariantList data); // OUTPUT PORT — universal [value]

    void valueChanged();
    void autoSendChanged();
    void stepSizeChanged();
    void minValueChanged();
    void maxValueChanged();

private:
    double m_value    = 0.0;
    bool   m_autoSend = false;
    double m_stepSize = 1.0;
    double m_minValue = -1e9;
    double m_maxValue =  1e9;
};

#endif // NUMBERINPUT_H
