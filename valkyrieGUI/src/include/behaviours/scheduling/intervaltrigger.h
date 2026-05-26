#ifndef INTERVALTRIGGER_H
#define INTERVALTRIGGER_H

#include <QObject>
#include <QTimer>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class IntervalTrigger : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int  days            READ days            WRITE setDays            NOTIFY daysChanged)
    Q_PROPERTY(int  hours           READ hours           WRITE setHours           NOTIFY hoursChanged)
    Q_PROPERTY(int  minutes         READ minutes         WRITE setMinutes         NOTIFY minutesChanged)
    Q_PROPERTY(int  seconds         READ seconds         WRITE setSeconds         NOTIFY secondsChanged)
    Q_PROPERTY(bool running         READ running                                  NOTIFY runningChanged)
    Q_PROPERTY(bool fireImmediately READ fireImmediately WRITE setFireImmediately NOTIFY fireImmediatelyChanged)
    Q_PROPERTY(QString nextTriggerIn READ nextTriggerIn                           NOTIFY nextTriggerInChanged)
    Q_PROPERTY(int  tickCount       READ tickCount                                NOTIFY tickCountChanged)

public:
    explicit IntervalTrigger(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject &state) override;

    int     days()            const { return m_days; }
    int     hours()           const { return m_hours; }
    int     minutes()         const { return m_minutes; }
    int     seconds()         const { return m_seconds; }
    bool    running()         const { return m_execTimer.isActive(); }
    bool    fireImmediately() const { return m_fireImmediately; }
    QString nextTriggerIn()   const { return m_nextTriggerIn; }
    int     tickCount()       const { return m_tickCount; }

public slots:
    void setDays(int v);
    void setHours(int v);
    void setMinutes(int v);
    void setSeconds(int v);
    void setFireImmediately(bool v);

    void startTrigger();
    void stopTrigger();
    void resetCount();
    void trigger();       // manual fire

signals:
    void execOut();
    void outputTick(int count);

    void daysChanged();
    void hoursChanged();
    void minutesChanged();
    void secondsChanged();
    void runningChanged();
    void fireImmediatelyChanged();
    void nextTriggerInChanged();
    void tickCountChanged();

private slots:
    void onExecTimer();
    void onCountdownTimer();

private:
    qint64 totalMs() const;
    void   updateCountdown();
    void   restartTimers();

    int     m_days            = 0;
    int     m_hours           = 0;
    int     m_minutes         = 1;
    int     m_seconds         = 0;
    bool    m_fireImmediately = false;
    int     m_tickCount       = 0;
    QString m_nextTriggerIn   = "--:--:--";

    QTimer  m_execTimer;
    QTimer  m_countdownTimer;   // 1 s tick for UI countdown
    qint64  m_nextFireMs = 0;   // epoch ms of next fire
};

#endif // INTERVALTRIGGER_H
