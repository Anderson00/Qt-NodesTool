#ifndef MERGENUMBERS_H
#define MERGENUMBERS_H

#include <QObject>
#include <QVariantList>
#include <QJsonObject>
#include <behaviours/behaviours.h>

/**
 * @brief MergeNumbers — combines two separate numeric inputs into pair outputs.
 *
 * Useful when two different nodes each output a single value and you need
 * to feed both into a slot that expects (double,double) or (int,double).
 *
 * Input ports : setA(double), setB(double), trigger()
 * Output ports: outputDD(double,double), outputID(int,double),
 *               outputII(int,int), outputData(QVariantList)
 */
class MergeNumbers : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double a        READ a        WRITE setA        NOTIFY aChanged)
    Q_PROPERTY(double b        READ b        WRITE setB        NOTIFY bChanged)
    Q_PROPERTY(bool   autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit MergeNumbers(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double a()        const;
    double b()        const;
    bool   autoSend() const;

public slots:
    void send();
    void trigger();
    void setA(double v);                     // INPUT PORT — sets A component
    void setB(double v);                     // INPUT PORT — sets B component
    void setAutoSend(bool enabled);

signals:
    void outputDD(double a, double b);       // OUTPUT PORT — (double, double)
    void outputID(int a, double b);          // OUTPUT PORT — (int, double)
    void outputII(int a, int b);             // OUTPUT PORT — (int, int)
    void outputData(QVariantList data);      // OUTPUT PORT — universal [a, b]

    void aChanged();
    void bChanged();
    void autoSendChanged();

private:
    double m_a        = 0.0;
    double m_b        = 0.0;
    bool   m_autoSend = false;
};

#endif // MERGENUMBERS_H
