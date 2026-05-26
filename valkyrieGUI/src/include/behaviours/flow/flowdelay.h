#ifndef FLOWDELAY_H
#define FLOWDELAY_H

#include <QObject>
#include <QJsonObject>
#include <QTimer>
#include <behaviours/behaviours.h>

class FlowDelay : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int  delayMs   READ delayMs   WRITE setDelayMs NOTIFY delayMsChanged)
    Q_PROPERTY(bool isWaiting READ isWaiting                  NOTIFY isWaitingChanged)

public:
    explicit FlowDelay(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int  delayMs()   const { return m_delayMs; }
    bool isWaiting() const { return m_waiting; }

public slots:
    void trigger();
    void setDelayMs(int ms);

signals:
    void execOut();
    void delayMsChanged();
    void isWaitingChanged();

private slots:
    void onTimeout();

private:
    int    m_delayMs = 1000;
    bool   m_waiting = false;
    QTimer m_timer;
};

#endif // FLOWDELAY_H
