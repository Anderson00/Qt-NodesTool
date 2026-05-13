// Include pybind11 first to avoid Qt 'slots' macro conflict
#include <pybind11/pybind11.h>
#include <pybind11/embed.h>
#include <pybind11/eval.h>
namespace py = pybind11;

#include "pythonengine.h"
#include <QCoreApplication>
#include <QDebug>
#include <QDir>
#include <QTimer>

namespace py = pybind11;

// Helper to convert QVariantMap to py::dict
static py::dict qvariantMapToPyDict(const QVariantMap& qmap) {
    py::dict pydict;
    for (auto it = qmap.constBegin(); it != qmap.constEnd(); ++it) {
        QVariant v = it.value();
        if (v.typeId() == QMetaType::Double) {
            pydict[py::str(it.key().toStdString())] = v.toDouble();
        } else if (v.typeId() == QMetaType::Int) {
            pydict[py::str(it.key().toStdString())] = v.toInt();
        } else if (v.typeId() == QMetaType::Bool) {
            pydict[py::str(it.key().toStdString())] = v.toBool();
        } else if (v.typeId() == QMetaType::QString) {
            pydict[py::str(it.key().toStdString())] = v.toString().toStdString();
        }
        // Simplified conversion. Full recursive conversion can be added if needed.
    }
    return pydict;
}

// Helper to convert py::dict back to QVariantMap
static QVariantMap pyDictToQVariantMap(const py::dict& pydict) {
    QVariantMap qmap;
    for (auto item : pydict) {
        QString key = QString::fromStdString(py::str(item.first));
        py::handle val = item.second;
        if (py::isinstance<py::bool_>(val)) {
            qmap[key] = val.cast<bool>();
        } else if (py::isinstance<py::int_>(val)) {
            qmap[key] = val.cast<int>();
        } else if (py::isinstance<py::float_>(val)) {
            qmap[key] = val.cast<double>();
        } else if (py::isinstance<py::str>(val)) {
            qmap[key] = QString::fromStdString(val.cast<std::string>());
        }
    }
    return qmap;
}

// ─────────────────────────────────────────────────────────────────────────────
// PythonWorker — runs in a separate QThread. Evaluates python code.
// ─────────────────────────────────────────────────────────────────────────────
class PythonWorker : public QObject {
    Q_OBJECT
public:
    PythonWorker() {}
    ~PythonWorker() {}

    unsigned long threadId() const { return m_threadId; }

public slots:
    void processTask(const PythonTask& task) {
        // Acquire GIL for execution safely in the worker thread.
        // It must encompass the entire try-catch block so that any py::error_already_set
        // exceptions are destructed while the GIL is still held.
        py::gil_scoped_acquire acquire;

        m_threadId = PyThreadState_Get()->thread_id;

        PythonResult result;
        result.id = task.id;

        try {

            py::module_ sys = py::module_::import("sys");
            
            // Setup sandbox and execution environment
            py::dict globals = py::globals();
            py::dict locals = py::dict();

            // Clear potentially dangerous builtins if strict sandboxing is needed
            // locals["__builtins__"] = ...

            // Inject inputs and variables
            locals["inputs"] = qvariantMapToPyDict(task.inputs);
            locals["variables"] = qvariantMapToPyDict(task.variables);
            
            // Output dictionary for the script to write to
            py::dict outputs;
            locals["output"] = outputs;

            // Setup a custom stdout to capture print() statements
            py::exec(R"(
import sys
import io
class StringOut:
    def __init__(self):
        self.buffer = []
    def write(self, text):
        if text != '\n':
            self.buffer.append(text)
    def flush(self):
        pass
sys.stdout = StringOut()
)", globals, locals);

            // Execute the user's script
            py::exec(task.script.toStdString(), globals, locals);

            // Extract captured stdout
            py::object stdoutObj = sys.attr("stdout");
            py::list buffer = stdoutObj.attr("buffer").cast<py::list>();
            for (auto item : buffer) {
                result.logs.append(QString::fromStdString(py::str(item)));
            }

            // Restore stdout
            sys.attr("stdout") = sys.attr("__stdout__");

            // Extract outputs populated by the script
            result.outputs = pyDictToQVariantMap(locals["output"].cast<py::dict>());
            
            // Extract the potentially modified variables dictionary
            result.variables = pyDictToQVariantMap(locals["variables"].cast<py::dict>());
            
            result.success = true;

        } catch (const std::exception& e) {
            result.success = false;
            result.error = QString::fromStdString(e.what());
        }

        emit taskFinished(result);
    }

signals:
    void taskFinished(const PythonResult& result);

private:
    unsigned long m_threadId = 0;
};

// ─────────────────────────────────────────────────────────────────────────────
// PythonEngine Implementation
// ─────────────────────────────────────────────────────────────────────────────
PythonEngine* PythonEngine::instance() {
    static PythonEngine* _instance = new PythonEngine();
    return _instance;
}

PythonEngine::PythonEngine(QObject *parent) : QObject(parent) {
    qRegisterMetaType<PythonTask>("PythonTask");
    qRegisterMetaType<PythonResult>("PythonResult");

    // Initialize Python in the main thread
    QString envPath = QCoreApplication::applicationDirPath() + "/python_env";
    if (QDir(envPath).exists()) {
        std::wstring wEnvPath = envPath.toStdWString();
        Py_SetPythonHome(wEnvPath.c_str());
    }
    
    // Setup Python once globally using Pybind11's RAII classes.
    // m_guard initializes the interpreter and acquires the GIL.
    m_guard = new py::scoped_interpreter();
    
    // m_release immediately releases the GIL on the main thread
    // so that the worker thread can acquire it.
    m_release = new py::gil_scoped_release();

    m_workerThread = new QThread(this);
    m_worker = new PythonWorker();
    m_worker->moveToThread(m_workerThread);

    connect(m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);
    connect(m_worker, &PythonWorker::taskFinished, this, &PythonEngine::handleWorkerFinished);

    m_workerThread->start();
}

PythonEngine::~PythonEngine() {
    m_workerThread->quit();
    m_workerThread->wait();

    // Destroy the release object first to re-acquire the GIL on the main thread,
    // then destroy the guard to finalize the interpreter safely.
    delete static_cast<py::gil_scoped_release*>(m_release);
    delete static_cast<py::scoped_interpreter*>(m_guard);
}

void PythonEngine::executeScript(const PythonTask& task) {
    // Invoke the processTask slot in the worker thread via Qt's queued connection
    QMetaObject::invokeMethod(m_worker, "processTask",
                              Qt::QueuedConnection,
                              Q_ARG(PythonTask, task));

    if (task.timeoutMs > 0) {
        QTimer::singleShot(task.timeoutMs, this, [this, id = task.id]() {
            this->killTask(id);
        });
    }
}

void PythonEngine::killTask(const QString& taskId) {
    // A simplified kill mechanism. In a production scenario with multiple queued tasks,
    // we would need to check if this task is currently running.
    // For now, we inject a KeyboardInterrupt into the worker thread.
    if (m_worker && m_worker->threadId() != 0) {
        py::gil_scoped_acquire acquire; // Needs GIL to set async exception
        PyThreadState_SetAsyncExc(m_worker->threadId(), PyExc_KeyboardInterrupt);
    }
}

void PythonEngine::handleWorkerFinished(const PythonResult& result) {
    emit scriptFinished(result);
}

#include "pythonengine.moc"
