#ifndef MAPRANGE_H
#define MAPRANGE_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class MapRange : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double inputValue  READ inputValue  NOTIFY inputValueChanged)
    Q_PROPERTY(double inMin       READ inMin        NOTIFY inMinChanged)
    Q_PROPERTY(double inMax       READ inMax        NOTIFY inMaxChanged)
    Q_PROPERTY(double outMin      READ outMin       NOTIFY outMinChanged)
    Q_PROPERTY(double outMax      READ outMax       NOTIFY outMaxChanged)
    Q_PROPERTY(bool   clamp       READ clamp        NOTIFY clampChanged)
    Q_PROPERTY(double mappedValue READ mappedValue  NOTIFY mappedValueChanged)

public:
    explicit MapRange(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double inputValue()  const;
    double inMin()       const;
    double inMax()       const;
    double outMin()      const;
    double outMax()      const;
    bool   clamp()       const;
    double mappedValue() const;

public slots:
    void setInputValue(double value);
    void setInMin(double v);
    void setInMax(double v);
    void setOutMin(double v);
    void setOutMax(double v);
    void setClamp(bool c);

signals:
    void outputMapped(double value);
    void outputString(QString value);

    void inputValueChanged();
    void inMinChanged();
    void inMaxChanged();
    void outMinChanged();
    void outMaxChanged();
    void clampChanged();
    void mappedValueChanged();

private:
    void compute();

    double m_inputValue  = 0.0;
    double m_inMin       = 0.0;
    double m_inMax       = 100.0;
    double m_outMin      = 0.0;
    double m_outMax      = 1.0;
    bool   m_clamp       = true;
    double m_mappedValue = 0.0;
};

#endif // MAPRANGE_H
