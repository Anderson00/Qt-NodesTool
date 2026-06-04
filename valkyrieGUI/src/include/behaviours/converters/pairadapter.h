#ifndef PAIRADAPTER_H
#define PAIRADAPTER_H

#include <QObject>
#include <QVariantList>
#include <QJsonObject>
#include <behaviours/behaviours.h>

/**
 * @brief PairAdapter — adapts a 2-value pair between all int/double combinations.
 *
 * Useful when a source emits (double,double) but a chart needs (int,double), etc.
 *
 * Input ports : setDD(double,double), setID(int,double), setII(int,int),
 *               setDI(double,int), setInputData(QVariantList), trigger()
 * Output ports: outputDD(double,double), outputID(int,double),
 *               outputII(int,int), outputDI(double,int),
 *               outputData(QVariantList)
 */
class PairAdapter : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double propA    READ propA    NOTIFY propAChanged)
    Q_PROPERTY(double propB    READ propB    NOTIFY propBChanged)
    Q_PROPERTY(bool   autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit PairAdapter(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double propA()    const;
    double propB()    const;
    bool   autoSend() const;

public slots:
    void send();
    void trigger();
    void setDD(double a, double b);          // INPUT PORT — (double, double)
    void setID(int a, double b);             // INPUT PORT — (int, double)
    void setII(int a, int b);                // INPUT PORT — (int, int)
    void setDI(double a, int b);             // INPUT PORT — (double, int)
    void setInputData(const QVariantList& d);// INPUT PORT — universal [a, b]
    void setAutoSend(bool enabled);

signals:
    void outputDD(double a, double b);       // OUTPUT PORT — (double, double)
    void outputID(int a, double b);          // OUTPUT PORT — (int, double)
    void outputII(int a, int b);             // OUTPUT PORT — (int, int)
    void outputDI(double a, int b);          // OUTPUT PORT — (double, int)
    void outputData(QVariantList data);      // OUTPUT PORT — universal [a, b]

    void propAChanged();
    void propBChanged();
    void autoSendChanged();

private:
    void setPair(double a, double b);

    double m_a        = 0.0;
    double m_b        = 0.0;
    bool   m_autoSend = false;
};

#endif // PAIRADAPTER_H
