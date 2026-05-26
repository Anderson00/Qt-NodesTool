#ifndef FLOWSEQUENCE_H
#define FLOWSEQUENCE_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class FlowSequence : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int  currentStep READ currentStep NOTIFY currentStepChanged)
    Q_PROPERTY(bool isRunning   READ isRunning   NOTIFY isRunningChanged)

public:
    explicit FlowSequence(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    int  currentStep() const { return m_step; }
    bool isRunning()   const { return m_running; }

public slots:
    void trigger();

signals:
    void step1();
    void step2();
    void step3();
    void currentStepChanged();
    void isRunningChanged();

private:
    int  m_step    = 0;
    bool m_running = false;
};

#endif // FLOWSEQUENCE_H
