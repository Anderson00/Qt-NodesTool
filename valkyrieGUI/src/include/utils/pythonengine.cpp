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

// Forward declarations for mutual recursion
static py::object  qvariantToPyObject(const QVariant& v);
static py::dict    qvariantMapToPyDict(const QVariantMap& qmap);
static py::list    qvariantListToPyList(const QVariantList& qlist);

static py::object qvariantToPyObject(const QVariant& v) {
    if (v.typeId() == QMetaType::Double)       return py::float_(v.toDouble());
    if (v.typeId() == QMetaType::Int)           return py::int_(v.toInt());
    if (v.typeId() == QMetaType::LongLong)      return py::int_(v.toLongLong());
    if (v.typeId() == QMetaType::Bool)          return py::bool_(v.toBool());
    if (v.typeId() == QMetaType::QString)       return py::str(v.toString().toStdString());
    if (v.typeId() == QMetaType::QVariantList)  return qvariantListToPyList(v.toList());
    if (v.typeId() == QMetaType::QVariantMap)   return qvariantMapToPyDict(v.toMap());
    if (v.typeId() == QMetaType::QStringList) {
        py::list lst;
        for (const QString& s : v.toStringList()) lst.append(py::str(s.toStdString()));
        return lst;
    }
    // Unmapped type: emit a warning and return None to avoid silent data loss
    qWarning() << "[PythonEngine] qvariantToPyObject: unsupported QVariant type"
               << v.typeName() << "— mapped to None";
    return py::none();
}

static py::dict qvariantMapToPyDict(const QVariantMap& qmap) {
    py::dict pydict;
    for (auto it = qmap.constBegin(); it != qmap.constEnd(); ++it) {
        pydict[py::str(it.key().toStdString())] = qvariantToPyObject(it.value());
    }
    return pydict;
}

static py::list qvariantListToPyList(const QVariantList& qlist) {
    py::list lst;
    for (const QVariant& v : qlist)
        lst.append(qvariantToPyObject(v));
    return lst;
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

        py::module_ sys = py::module_::import("sys");
        // Save original stdout so we can always restore it (success or error)
        py::object origStdout = sys.attr("stdout");

        try {
            // Setup sandbox and execution environment
            py::dict globals = py::globals();
            py::dict locals = py::dict();

            // NOTE: No sandbox active. Scripts have full Python access.
            // Do NOT load workspaces from untrusted sources.

            // Inject inputs and variables
            locals["inputs"]    = qvariantMapToPyDict(task.inputs);
            locals["variables"] = qvariantMapToPyDict(task.variables);

            // Output dictionary for the script to write to
            py::dict outputs;
            locals["output"] = outputs;

            // Redirect stdout to capture print() statements
            py::exec(R"(
import sys
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

            // Restore stdout (success path)
            sys.attr("stdout") = origStdout;

            // Extract outputs populated by the script
            result.outputs   = pyDictToQVariantMap(locals["output"].cast<py::dict>());
            result.variables = pyDictToQVariantMap(locals["variables"].cast<py::dict>());
            result.success   = true;

        } catch (const std::exception& e) {
            // Always restore stdout, even on error, to prevent a permanently
            // broken stdout for subsequent script executions
            try { sys.attr("stdout") = origStdout; } catch (...) {}
            result.success = false;
            result.error   = QString::fromStdString(e.what());
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
    // Track the current task so stale timeouts cannot abort newer tasks
    m_currentTaskId = task.id;

    // Invoke the processTask slot in the worker thread via Qt's queued connection
    QMetaObject::invokeMethod(m_worker, "processTask",
                              Qt::QueuedConnection,
                              Q_ARG(PythonTask, task));

    if (task.timeoutMs > 0) {
        QTimer::singleShot(task.timeoutMs, this, [this, id = task.id]() {
            // Only kill if the task with this id is still the active one
            if (m_currentTaskId == id)
                this->killTask(id);
        });
    }
}

void PythonEngine::killTask(const QString& taskId) {
    // Only interrupt if this task is still the one currently executing
    if (m_currentTaskId != taskId) return;

    if (m_worker && m_worker->threadId() != 0) {
        py::gil_scoped_acquire acquire; // Needs GIL to set async exception
        PyThreadState_SetAsyncExc(m_worker->threadId(), PyExc_KeyboardInterrupt);
    }
}

void PythonEngine::handleWorkerFinished(const PythonResult& result) {
    // Clear current task tracking when the task completes
    if (m_currentTaskId == result.id)
        m_currentTaskId.clear();

    emit scriptFinished(result);
}

#include "pythonengine.moc"
