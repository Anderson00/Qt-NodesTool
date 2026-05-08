#ifndef SIGNALGENERATOR_H
#define SIGNALGENERATOR_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class SignalGenerator : public Behaviours
{
    Q_OBJECT

public:
    explicit SignalGenerator(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

public:
    Q_INVOKABLE void emitValue(double value);

signals:
    void outputValue(double value);
    void outputString(QString value);
};

#endif // SIGNALGENERATOR_H
