#ifndef PYTHONENGINE_H
#define PYTHONENGINE_H

#include <QObject>
#include <QString>
#include <QThread>
#include <QMutex>
#include <QWaitCondition>
#include <QVariantMap>
#include <QStringList>

// ─────────────────────────────────────────────────────────────────────────────
// PythonEngine — singleton managing the embedded Python interpreter (pybind11).
// Provides an execution queue and runs scripts in a dedicated QThread to prevent
// blocking the main Qt GUI thread. Implements a security sandbox.
// ─────────────────────────────────────────────────────────────────────────────

struct PythonTask {
    QString id;
    QString script;
    QVariantMap inputs;
    QVariantMap variables;
    int timeoutMs = 5000;
};

struct PythonResult {
    QString id;
    bool success = false;
    QString error;
    QVariantMap outputs;
    QVariantMap variables;
    QStringList logs;
};

// Forward declare the worker class
class PythonWorker;

class PythonEngine : public QObject
{
    Q_OBJECT
public:
    static PythonEngine* instance();

    // Enqueue a script for execution
    void executeScript(const PythonTask& task);
    void killTask(const QString& taskId);

signals:
    // Emitted when a task finishes (success or failure)
    void scriptFinished(const PythonResult& result);

private slots:
    void handleWorkerFinished(const PythonResult& result);

private:
    explicit PythonEngine(QObject *parent = nullptr);
    ~PythonEngine();

    QThread* m_workerThread;
    PythonWorker* m_worker;
    void* m_guard = nullptr;
    void* m_release = nullptr;
};

Q_DECLARE_METATYPE(PythonTask)
Q_DECLARE_METATYPE(PythonResult)

#endif // PYTHONENGINE_H
