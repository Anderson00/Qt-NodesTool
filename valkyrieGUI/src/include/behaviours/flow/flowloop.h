#ifndef FLOWLOOP_H
#define FLOWLOOP_H

#include <QObject>
#include <QJsonObject>
#include <QTimer>
#include <behaviours/behaviours.h>

class FlowLoop : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int  iterations        READ iterations        WRITE setIterations NOTIFY iterationsChanged)
    Q_PROPERTY(int  currentIteration  READ currentIteration                      NOTIFY currentIterationChanged)
    Q_PROPERTY(bool isRunning         READ isRunning                             NOTIFY isRunningChanged)

public:
    explicit FlowLoop(QObject *parent = nullptr);
    ~FlowLoop();

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int  iterations()       const { return m_iterations; }
    int  currentIteration() const { return m_current; }
    bool isRunning()        const { return m_running; }

public slots:
    void trigger();
    void setIterations(int v);
    void breakLoop();

signals:
    void body();
    void completed();
    void outputIndex(int index);
    void iterationsChanged();
    void currentIterationChanged();
    void isRunningChanged();

private slots:
    void onTick();

private:
    int    m_iterations = 3;
    int    m_current    = 0;
    bool   m_running    = false;
    bool   m_break      = false;
    QTimer m_timer;
};

#endif // FLOWLOOP_H
