#ifndef COUNTER_H
#define COUNTER_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class Counter : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(int step  READ step  WRITE setStep NOTIFY stepChanged)

public:
    explicit Counter(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int count() const;
    int step()  const;

public slots:
    void increment();
    void decrement();
    void reset();
    void setValue(int value);
    void setStep(int step);

signals:
    void outputCount(int count);
    void outputValue(double value);

    void countChanged();
    void stepChanged();

private:
    void emitAll();

    int m_count = 0;
    int m_step  = 1;
};

#endif // COUNTER_H
