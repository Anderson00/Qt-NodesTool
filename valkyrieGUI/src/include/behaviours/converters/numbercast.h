#ifndef NUMBERCAST_H
#define NUMBERCAST_H

#include <QObject>
#include <QVariantList>
#include <QJsonObject>
#include <behaviours/behaviours.h>

/**
 * @brief NumberCast — universal numeric type converter.
 *
 * Accepts any numeric type on its input ports and re-emits as
 * double, int, bool and QString on separate output ports.
 * Also exposes a universal outputData(QVariantList) port.
 *
 * Input ports : setInput(double), setInputInt(int), trigger()
 * Output ports: outputDouble(double), outputInt(int),
 *               outputBool(bool), outputString(QString), outputData(QVariantList)
 */
class NumberCast : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(double value    READ value    NOTIFY valueChanged)
    Q_PROPERTY(bool   autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit NumberCast(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    double value()    const;
    bool   autoSend() const;

public slots:
    void send();
    void trigger();                       // INPUT PORT — fire send()
    void setInput(double v);              // INPUT PORT — accept double
    void setInputInt(int v);              // INPUT PORT — accept int
    void setAutoSend(bool enabled);

signals:
    void outputDouble(double value);      // OUTPUT PORT
    void outputInt(int value);            // OUTPUT PORT
    void outputBool(bool value);          // OUTPUT PORT
    void outputString(QString value);     // OUTPUT PORT
    void outputData(QVariantList data);   // OUTPUT PORT — universal [value]

    void valueChanged();
    void autoSendChanged();

private:
    double m_value    = 0.0;
    bool   m_autoSend = false;
};

#endif // NUMBERCAST_H
