#ifndef PROCESSLAUNCHER_H
#define PROCESSLAUNCHER_H

#include <QObject>
#include <QJsonObject>
#include <QProcess>
#include <QSysInfo>
#include <behaviours/behaviours.h>

class ProcessLauncher : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(bool    isRunning   READ isRunning   NOTIFY isRunningChanged)
    Q_PROPERTY(int     exitCode    READ exitCode    NOTIFY exitCodeChanged)
    Q_PROPERTY(QString workingDir  READ workingDir  WRITE setWorkingDir NOTIFY workingDirChanged)
    Q_PROPERTY(int     pid         READ pid         NOTIFY pidChanged)

public:
    explicit ProcessLauncher(QObject *parent = nullptr);
    ~ProcessLauncher();

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    bool    isRunning()  const { return m_isRunning; }
    int     exitCode()   const { return m_exitCode; }
    QString workingDir() const { return m_workingDir; }
    int     pid()        const { return m_pid; }

    void setWorkingDir(const QString& path);

public slots:
    void launch(QString command, QStringList args);
    void launchShell(QString command);
    void kill();
    void setWorkingDirSlot(QString path);

signals:
    // Node outputs
    void stdoutReceived(QString output);
    void stderrReceived(QString output);
    void finished(int exitCode);

    // Internal QML bridge
    void internalStdout(QString text);
    void internalStderr(QString text);
    void internalFinished(int exitCode);
    void internalStarted();

    // Property notifiers
    void isRunningChanged();
    void exitCodeChanged();
    void workingDirChanged();
    void pidChanged();

private:
    void setupProcess(QProcess* proc);
    void cleanupProcess();

    QProcess* m_process   = nullptr;
    bool      m_isRunning = false;
    int       m_exitCode  = 0;
    QString   m_workingDir;
    int       m_pid       = 0;
    QString   m_lastCommand;
};

#endif // PROCESSLAUNCHER_H
