#ifndef TIMERNODE_H
#define TIMERNODE_H

#include <QObject>
#include <QTimer>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class TimerNode : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int  interval  READ interval  WRITE setInterval  NOTIFY intervalChanged)
    Q_PROPERTY(bool running   READ running   NOTIFY runningChanged)
    Q_PROPERTY(int  tickCount READ tickCount NOTIFY tickCountChanged)

public:
    explicit TimerNode(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int  interval()  const;
    bool running()   const;
    int  tickCount() const;

public slots:
    void setInterval(int ms);
    void startTimer();
    void stopTimer();
    void trigger();
    void resetCount();

signals:
    void triggered();
    void outputTick(int count);
    void outputValue(double value);

    void intervalChanged();
    void runningChanged();
    void tickCountChanged();

private:
    QTimer m_timer;
    int    m_interval  = 1000;
    int    m_tickCount = 0;
};

#endif // TIMERNODE_H
