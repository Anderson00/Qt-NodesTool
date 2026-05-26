#ifndef PAIRINPUT_H
#define PAIRINPUT_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class PairInput : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double xValue   READ xValue   WRITE setXValue   NOTIFY xValueChanged)
    Q_PROPERTY(double yValue   READ yValue   WRITE setYValue   NOTIFY yValueChanged)
    Q_PROPERTY(bool   autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit PairInput(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double xValue()   const;
    double yValue()   const;
    bool   autoSend() const;

public slots:
    void send();
    void trigger();
    void setXValue(double x);
    void setYValue(double y);
    void setAutoSend(bool enabled);

signals:
    void outputXY(double x, double y);   // OUTPUT PORT — (x, y) pair
    void outputData(QVariantList data);  // OUTPUT PORT — universal [x, y]

    void xValueChanged();
    void yValueChanged();
    void autoSendChanged();

private:
    double m_xValue   = 0.0;
    double m_yValue   = 0.0;
    bool   m_autoSend = false;
};

#endif // PAIRINPUT_H
