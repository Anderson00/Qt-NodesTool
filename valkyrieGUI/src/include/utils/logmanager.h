#pragma once

#include <QObject>
#include <QString>

class QQmlEngine;
class QJSEngine;

class LogManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString lastMessage READ lastMessage NOTIFY newEntry)
    Q_PROPERTY(QString lastType    READ lastType    NOTIFY newEntry)
    Q_PROPERTY(QString lastTime    READ lastTime    NOTIFY newEntry)
    Q_PROPERTY(int     warnCount   READ warnCount   NOTIFY newEntry)
    Q_PROPERTY(int     errorCount  READ errorCount  NOTIFY newEntry)

public:
    static LogManager* instance();
    static QObject*    qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QString lastMessage() const { return m_lastMessage; }
    QString lastType()    const { return m_lastType; }
    QString lastTime()    const { return m_lastTime; }
    int     warnCount()   const { return m_warnCount; }
    int     errorCount()  const { return m_errorCount; }

    // Called from the Qt message handler (may be any thread).
    void addEntry(const QString& message, const QString& type);

    Q_INVOKABLE void log(const QString& message, const QString& type = "info");
    Q_INVOKABLE void clear();

signals:
    void newEntry();

private:
    explicit LogManager(QObject* parent = nullptr);
    QString m_lastMessage;
    QString m_lastType = "info";
    QString m_lastTime;
    int     m_warnCount  = 0;
    int     m_errorCount = 0;
};
