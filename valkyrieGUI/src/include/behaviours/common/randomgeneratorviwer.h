#ifndef RANDOMGENERATORVIWER_H
#define RANDOMGENERATORVIWER_H

#include <QObject>
#include <behaviours/behaviours.h>

class RandomGeneratorViwer : public Behaviours
{
    Q_OBJECT
public:
    RandomGeneratorViwer(QObject *parent = nullptr);
    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

public slots:
    double genNewNumber(double min, double max);

signals:
    void currentNumber(double value);

private:
    double m_currentNumber = 0.0;
};

#endif // RANDOMGENERATORVIWER_H
