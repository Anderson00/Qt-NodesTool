#ifndef RANDOMGENERATORVIEWER_H
#define RANDOMGENERATORVIEWER_H

#include <QObject>
#include <behaviours/behaviours.h>

class RandomGeneratorViewer : public Behaviours
{
    Q_OBJECT
public:
    RandomGeneratorViewer(QObject *parent = nullptr);
    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

public slots:
    double genNewNumber(double min, double max);

signals:
    void currentNumber(double value);

private:
    double m_currentNumber = 0.0;
};

#endif // RANDOMGENERATORVIEWER_H
