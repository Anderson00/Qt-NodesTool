#ifndef PYTHONBEHAVIOUR_H
#define PYTHONBEHAVIOUR_H

#include <QObject>
#include <QJsonObject>
#include <QVariantMap>
#include <behaviours/behaviours.h>
#include "utils/pythonengine.h"

// ─────────────────────────────────────────────────────────────────────────────
// PythonBehaviour — a customizable Node that executes user-defined Python
// scripts via the PythonEngine.
// ─────────────────────────────────────────────────────────────────────────────
class PythonBehaviour : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString script       READ script       WRITE setScript       NOTIFY scriptChanged)
    Q_PROPERTY(bool    isRunning    READ isRunning                          NOTIFY isRunningChanged)
    Q_PROPERTY(bool    hasError     READ hasError                           NOTIFY hasErrorChanged)
    Q_PROPERTY(QString errorMsg     READ errorMsg                           NOTIFY hasErrorChanged)
    Q_PROPERTY(int     lastExecTime READ lastExecTime                       NOTIFY lastExecTimeChanged)
    Q_PROPERTY(bool    autoRun      READ autoRun      WRITE setAutoRun      NOTIFY autoRunChanged)
    Q_PROPERTY(QStringList logs     READ logs                               NOTIFY logsChanged)

public:
    explicit PythonBehaviour(QObject *parent = nullptr);
    ~PythonBehaviour();

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString script()       const { return m_script; }
    bool    isRunning()    const { return m_isRunning; }
    bool    hasError()     const { return !m_error.isEmpty(); }
    QString errorMsg()     const { return m_error; }
    int     lastExecTime() const { return m_lastExecTime; }
    bool    autoRun()      const { return m_autoRun; }
    QStringList logs()     const { return m_logs; }

public slots:
    void setScript(const QString& script);
    void setAutoRun(bool autoRun);
    
    // Evaluate node inputs. Whenever an input changes, if autoRun is true, run() is called.
    void updateInput(const QString& name, const QVariant& value);

    Q_INVOKABLE void run();
    Q_INVOKABLE void clearLogs();
    Q_INVOKABLE void injectDocs();

signals:
    // Emitted to dynamically update the output ports
    void outputResult(const QString& name, const QVariant& value);

    void scriptChanged();
    void isRunningChanged();
    void hasErrorChanged();
    void lastExecTimeChanged();
    void autoRunChanged();
    void logsChanged();

private slots:
    void handleScriptFinished(const PythonResult& result);

private:
    QString m_script;
    bool    m_isRunning = false;
    QString m_error;
    int     m_lastExecTime = 0;
    bool    m_autoRun = false;
    QStringList m_logs;
    QVariantMap m_inputs;

    QString m_currentTaskId;
    qint64  m_startTime = 0;
};

#endif // PYTHONBEHAVIOUR_H
