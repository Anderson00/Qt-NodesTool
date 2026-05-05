#ifndef CLAMP_H
#define CLAMP_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class Clamp : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double inputValue  READ inputValue  NOTIFY inputValueChanged)
    Q_PROPERTY(double rangeMin    READ rangeMin    WRITE setMin NOTIFY rangeMinChanged)
    Q_PROPERTY(double rangeMax    READ rangeMax    WRITE setMax NOTIFY rangeMaxChanged)
    Q_PROPERTY(double clampedValue READ clampedValue NOTIFY clampedValueChanged)
    Q_PROPERTY(double normalized  READ normalized  NOTIFY normalizedChanged)

public:
    explicit Clamp(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double inputValue()   const;
    double rangeMin()     const;
    double rangeMax()     const;
    double clampedValue() const;
    double normalized()   const;

public slots:
    void setInput(double value);
    void setMin(double min);
    void setMax(double max);

signals:
    void outputValue(double value);
    void outputNormalized(double value);

    void inputValueChanged();
    void rangeMinChanged();
    void rangeMaxChanged();
    void clampedValueChanged();
    void normalizedChanged();

private:
    void compute();

    double m_inputValue = 0.0;
    double m_min        = 0.0;
    double m_max        = 1.0;
    double m_clamped    = 0.0;
    double m_normalized = 0.0;
};

#endif // CLAMP_H
