#ifndef GAUGEVIEWER_H
#define GAUGEVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class GaugeViewer : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double inputValue READ inputValue NOTIFY inputValueChanged)
    Q_PROPERTY(double gaugeMin   READ gaugeMin   NOTIFY gaugeMinChanged)
    Q_PROPERTY(double gaugeMax   READ gaugeMax   NOTIFY gaugeMaxChanged)
    Q_PROPERTY(double warnThresh READ warnThresh NOTIFY warnThreshChanged)
    Q_PROPERTY(double critThresh READ critThresh NOTIFY critThreshChanged)
    Q_PROPERTY(QString unitLabel READ unitLabel  NOTIFY unitLabelChanged)

public:
    explicit GaugeViewer(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double  inputValue() const;
    double  gaugeMin()   const;
    double  gaugeMax()   const;
    double  warnThresh() const;
    double  critThresh() const;
    QString unitLabel()  const;

public slots:
    void setInputValue(double value);
    void setMin(double v);
    // Universal input — [value] or [value, min, max]
    void setInputData(const QVariantList& data);
    void setMax(double v);
    void setWarn(double v);
    void setCrit(double v);
    void setUnit(const QString& unit);

signals:
    void internalSetValue(double value);
    void internalSetMin(double v);
    void internalSetMax(double v);
    void internalSetWarn(double v);
    void internalSetCrit(double v);
    void internalSetUnit(const QString& unit);

    void inputValueChanged();
    void gaugeMinChanged();
    void gaugeMaxChanged();
    void warnThreshChanged();
    void critThreshChanged();
    void unitLabelChanged();

private:
    double  m_inputValue = 0.0;
    double  m_gaugeMin   = 0.0;
    double  m_gaugeMax   = 100.0;
    double  m_warnThresh = 70.0;
    double  m_critThresh = 90.0;
    QString m_unitLabel;
};

#endif // GAUGEVIEWER_H
