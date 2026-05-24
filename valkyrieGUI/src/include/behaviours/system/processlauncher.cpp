#include "processlauncher.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(ProcessLauncher, "Process Launcher", "Launch system commands and capture stdout/stderr", "system", 4, 3)

ProcessLauncher::ProcessLauncher(QObject *parent)
    : Behaviours(parent)
{
    setWidth(380);
    setHeight(340);
    setContentHeight(340);
    setQmlBodyUrl("qrc:/behaviours/system/ProcessLauncher.qml");

    addInputOutputExclusion(QList<QString>({
        "internalStdout(QString)",
        "internalStderr(QString)",
        "internalFinished(int)",
        "internalStarted()"
    }));
}

ProcessLauncher::~ProcessLauncher()
{
    cleanupProcess();
}

QMap<QString, QVariant> ProcessLauncher::loadInfos()
{
    return ProcessLauncher::static_infos();
}

QMap<QString, QVariant> ProcessLauncher::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "ProcessLauncher"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "ProcessLauncher"},
        {"desc",          "Launch system commands and capture stdout/stderr"},
        {"inputs_count",  "4"},
        {"outputs_count", "3"}
    });
}

void ProcessLauncher::setWorkingDir(const QString& path)
{
    if (m_workingDir != path) {
        m_workingDir = path;
        emit workingDirChanged();
    }
}

void ProcessLauncher::setWorkingDirSlot(QString path)
{
    setWorkingDir(path);
}

void ProcessLauncher::setupProcess(QProcess* proc)
{
    if (!m_workingDir.isEmpty())
        proc->setWorkingDirectory(m_workingDir);

    connect(proc, &QProcess::readyReadStandardOutput, this, [this]() {
        if (!m_process) return;
        QString text = QString::fromLocal8Bit(m_process->readAllStandardOutput());
        emit stdoutReceived(text);
        emit internalStdout(text);
    });

    connect(proc, &QProcess::readyReadStandardError, this, [this]() {
        if (!m_process) return;
        QString text = QString::fromLocal8Bit(m_process->readAllStandardError());
        emit stderrReceived(text);
        emit internalStderr(text);
    });

    connect(proc, &QProcess::started, this, [this]() {
        m_isRunning = true;
        m_pid       = static_cast<int>(m_process ? m_process->processId() : 0);
        emit isRunningChanged();
        emit pidChanged();
        emit internalStarted();
    });

    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this](int code, QProcess::ExitStatus) {
        m_exitCode  = code;
        m_isRunning = false;
        m_pid       = 0;
        emit exitCodeChanged();
        emit isRunningChanged();
        emit pidChanged();
        emit finished(code);
        emit internalFinished(code);
    });
}

void ProcessLauncher::cleanupProcess()
{
    if (m_process) {
        if (m_process->state() != QProcess::NotRunning) {
            m_process->kill();
            m_process->waitForFinished(1000);
        }
        m_process->deleteLater();
        m_process = nullptr;
    }
}

void ProcessLauncher::launch(QString command, QStringList args)
{
    cleanupProcess();
    m_lastCommand = command;

    m_process = new QProcess(this);
    setupProcess(m_process);
    m_process->start(command, args);
}

void ProcessLauncher::launchShell(QString command)
{
    cleanupProcess();
    m_lastCommand = command;

    QStringList args;
#ifdef Q_OS_WIN
    QString shell = "cmd";
    args << "/c" << command;
#else
    QString shell = "sh";
    args << "-c" << command;
#endif

    m_process = new QProcess(this);
    setupProcess(m_process);
    m_process->start(shell, args);
}

void ProcessLauncher::kill()
{
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->kill();
    }
}

QJsonObject ProcessLauncher::saveState() const
{
    QJsonObject state;
    state["lastCommand"] = m_lastCommand;
    state["workingDir"]  = m_workingDir;
    return state;
}

void ProcessLauncher::loadState(const QJsonObject& state)
{
    m_lastCommand = state.value("lastCommand").toString();
    if (state.contains("workingDir"))
        setWorkingDir(state["workingDir"].toString());
}
