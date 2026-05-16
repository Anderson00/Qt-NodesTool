#ifndef CRONTRIGGER_H
#define CRONTRIGGER_H

#include <QObject>
#include <QTimer>
#include <QDateTime>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class CronTrigger : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString  cronExpression  READ cronExpression  WRITE setCronExpression  NOTIFY cronExpressionChanged)
    Q_PROPERTY(bool     enabled         READ enabled         WRITE setEnabled         NOTIFY enabledChanged)
    Q_PROPERTY(bool     isValid         READ isValid                                  NOTIFY isValidChanged)
    Q_PROPERTY(QString  description     READ description                              NOTIFY descriptionChanged)
    Q_PROPERTY(QString  nextOccurrence  READ nextOccurrence                           NOTIFY nextOccurrenceChanged)
    Q_PROPERTY(QString  lastOccurrence  READ lastOccurrence                           NOTIFY lastOccurrenceChanged)
    Q_PROPERTY(int      fireCount       READ fireCount                                NOTIFY fireCountChanged)

public:
    explicit CronTrigger(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject &state) override;

    QString cronExpression() const { return m_cronExpression; }
    bool    enabled()        const { return m_enabled; }
    bool    isValid()        const { return m_isValid; }
    QString description()    const { return m_description; }
    QString nextOccurrence() const { return m_nextOccurrence; }
    QString lastOccurrence() const { return m_lastOccurrence; }
    int     fireCount()      const { return m_fireCount; }

public slots:
    void setCronExpression(const QString &expr);
    void setEnabled(bool v);
    void testFire();   // manual one-shot test, does not affect state

signals:
    void execOut();

    void cronExpressionChanged();
    void enabledChanged();
    void isValidChanged();
    void descriptionChanged();
    void nextOccurrenceChanged();
    void lastOccurrenceChanged();
    void fireCountChanged();

private slots:
    void onCheckTimer();

private:
    void parseExpression();
    void updateDescription();
    void updateNextOccurrence();
    QString buildDescription() const;
    QDateTime computeNext() const;

    QString  m_cronExpression  = "0 * * * *";
    bool     m_enabled         = false;
    bool     m_isValid         = false;
    QString  m_description;
    QString  m_nextOccurrence;
    QString  m_lastOccurrence;
    int      m_fireCount       = 0;

    // Anti-double-fire: store last fired minute epoch
    qint64   m_lastFiredMinute = -1;

    QTimer   m_checkTimer;   // fires every 30 s
};

#endif // CRONTRIGGER_H
