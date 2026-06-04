#ifndef RATELIMITER_H
#define RATELIMITER_H

#include <QObject>
#include <QJsonObject>
#include <QTimer>
#include <QElapsedTimer>
#include <QVariant>
#include <behaviours/behaviours.h>

class RateLimiter : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString mode        READ mode        WRITE setMode        NOTIFY modeChanged)
    Q_PROPERTY(int     intervalMs  READ intervalMs  WRITE setIntervalMs  NOTIFY intervalMsChanged)
    Q_PROPERTY(int     droppedCount READ droppedCount NOTIFY droppedCountChanged)
    Q_PROPERTY(int     passedCount  READ passedCount  NOTIFY passedCountChanged)

public:
    explicit RateLimiter(QObject *parent = nullptr);

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject &state) override;

    QString mode()         const;
    int     intervalMs()   const;
    int     droppedCount() const;
    int     passedCount()  const;

    void setMode(QString mode);
    void setIntervalMs(int ms);

public slots:
    void push(QVariant value);

signals:
    // Node output
    void passed(QVariant value);

    // Internal QML-only signals
    void internalPassed(QVariant value);
    void internalDropped();

    // Property notifiers
    void modeChanged();
    void intervalMsChanged();
    void droppedCountChanged();
    void passedCountChanged();

private:
    QString       m_mode        = "throttle";
    int           m_intervalMs  = 500;
    int           m_droppedCount = 0;
    int           m_passedCount  = 0;

    // Throttle state
    QElapsedTimer m_elapsed;
    bool          m_elapsedStarted = false;

    // Debounce state
    QTimer        m_debounceTimer;
    QVariant      m_pendingValue;
};

#endif // RATELIMITER_H
