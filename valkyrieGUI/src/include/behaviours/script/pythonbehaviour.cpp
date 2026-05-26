#include "pythonbehaviour.h"
#include "behaviours/behaviourregistry.h"
#include "model/variablemanager.h"
#include <QUuid>
#include <QDateTime>
#include <QFile>
#include <QJsonObject>
#include <QUrl>

#ifdef slots
#undef slots
#include <pybind11/embed.h>
#define slots Q_SLOTS
#else
#include <pybind11/embed.h>
#endif

REGISTER_BEHAVIOUR(PythonBehaviour,
    "Python Script",
    "Execute custom Python code with injected inputs and variables",
    "script", 1, 1)

PythonBehaviour::PythonBehaviour(QObject *parent)
    : Behaviours(parent)
{
    setWidth(360);
    setHeight(280);
    setContentHeight(280);
    setQmlBodyUrl("qrc:/behaviours/script/PythonScriptViewer.qml");

    addInputOutputExclusion(QList<QString>({
        "scriptChanged()",
        "isRunningChanged()",
        "hasErrorChanged()",
        "lastExecTimeChanged()",
        "autoRunChanged()",
        "logsChanged()"
    }));

    // Start with a basic example script
    m_script = "# Python script\n"
               "# You can access inputs via the 'inputs' dictionary\n"
               "# You can access global variables via the 'variables' dictionary\n"
               "# Write your results to the 'output' dictionary\n\n"
               "val = inputs.get('in_1', 0)\n"
               "print('Executing script with val:', val)\n\n"
               "output['out_1'] = val * 2\n";

    connect(PythonEngine::instance(), &PythonEngine::scriptFinished,
            this, &PythonBehaviour::handleScriptFinished);
}

PythonBehaviour::~PythonBehaviour() {
}

void PythonBehaviour::onPinsReady()
{
    // inputs
    setPinTypeForSignature("updateInput(QString,QVariant)", Connections::AnyType);
    // outputs
    setPinTypeForSignature("outputResult(QString,QVariant)", Connections::AnyType);
}

QMap<QString, QVariant> PythonBehaviour::loadInfos() { return static_infos(); }

QMap<QString, QVariant> PythonBehaviour::static_infos() {
    return QMap<QString, QVariant>({
        {"name",          "PythonBehaviour"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "PythonBehaviour"},
        {"desc",          "Execute custom Python code"},
        {"inputs_count",  "1"}, // Can be dynamic later
        {"outputs_count", "1"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

void PythonBehaviour::setScript(const QString& script) {
    if (m_script != script) {
        m_script = script;
        emit scriptChanged();
        // Do not autoRun during loadState() — inputs and variables may not yet
        // be restored, which would produce incorrect/misleading results.
        if (m_autoRun && !m_loading) run();
    }
}

void PythonBehaviour::setAutoRun(bool autoRun) {
    if (m_autoRun != autoRun) {
        m_autoRun = autoRun;
        emit autoRunChanged();
    }
}

void PythonBehaviour::setTimeoutMs(int timeoutMs) {
    if (m_timeoutMs != timeoutMs) {
        m_timeoutMs = timeoutMs;
        emit timeoutMsChanged();
    }
}

void PythonBehaviour::updateInput(const QString& name, const QVariant& value) {
    m_inputs[name] = value;
    if (m_autoRun && !m_isRunning) {
        run();
    }
}

void PythonBehaviour::clearLogs() {
    m_logs.clear();
    emit logsChanged();
}

void PythonBehaviour::injectDocs() {
    QString docs = "# ── AVAILABLE VARIABLES ──\n";
    VariableManager* vm = VariableManager::instance();
    if (vm->count() == 0) {
        docs += "# (No global variables created yet)\n";
    } else {
        for (int i = 0; i < vm->count(); ++i) {
            NodeVariable* v = vm->variableAt(i);
            if (v) docs += QString("# variables.get('%1')  # Type: %2\n").arg(v->name(), v->type());
        }
    }
    
    docs += "# ── AVAILABLE INPUTS ──\n";
    if (m_inputs.isEmpty()) {
        docs += "# inputs.get('in_1')\n";
    } else {
        for (auto it = m_inputs.constBegin(); it != m_inputs.constEnd(); ++it) {
            docs += QString("# inputs.get('%1')\n").arg(it.key());
        }
    }
    docs += "# ─────────────────────────\n\n";

    // Remove old auto-generated docs if present
    QString current = m_script;
    if (current.startsWith("# ── AVAILABLE")) {
        int endIdx = current.indexOf("# ─────────────────────────\n\n");
        if (endIdx != -1) {
            current.remove(0, endIdx + 29); // Length of the separator + \n\n
        }
    }
    
    setScript(docs + current);
}

// ── Execution ────────────────────────────────────────────────────────────────

void PythonBehaviour::run() {
    if (m_isRunning || m_script.trimmed().isEmpty()) return;

    m_isRunning = true;
    m_error.clear();
    emit isRunningChanged();
    emit hasErrorChanged();

    m_currentTaskId = QUuid::createUuid().toString();
    m_startTime = QDateTime::currentMSecsSinceEpoch();

    PythonTask task;
    task.id = m_currentTaskId;
    task.script = m_script;
    task.inputs = m_inputs;
    task.timeoutMs = m_timeoutMs;
    
    // Inject all global variables
    VariableManager* vm = VariableManager::instance();
    for (int i = 0; i < vm->count(); ++i) {
        NodeVariable* v = vm->variableAt(i);
        if (v) task.variables[v->name()] = v->parsedValue();
    }

    PythonEngine::instance()->executeScript(task);
}

void PythonBehaviour::handleScriptFinished(const PythonResult& result) {
    if (result.id != m_currentTaskId) return;

    m_isRunning = false;
    m_lastExecTime = QDateTime::currentMSecsSinceEpoch() - m_startTime;
    
    if (!result.success) {
        m_error = result.error;
    } else {
        m_error.clear();
        
        // Append logs
        if (!result.logs.isEmpty()) {
            m_logs.append(result.logs);
            // Keep last 100 lines: erase in one O(N) operation instead of
            // calling removeFirst() in a loop which is O(N²)
            if (m_logs.size() > 100)
                m_logs.erase(m_logs.begin(), m_logs.begin() + (m_logs.size() - 100));
            emit logsChanged();
        }

        // Handle outputs
        for (auto it = result.outputs.constBegin(); it != result.outputs.constEnd(); ++it) {
            emit outputResult(it.key(), it.value());
        }

        // Handle variable updates (two-way binding)
        VariableManager* vm = VariableManager::instance();
        for (auto it = result.variables.constBegin(); it != result.variables.constEnd(); ++it) {
            NodeVariable* targetVar = nullptr;
            for (int i = 0; i < vm->count(); ++i) {
                NodeVariable* v = vm->variableAt(i);
                if (v && v->name() == it.key()) {
                    targetVar = v;
                    break;
                }
            }
            
            if (targetVar && !targetVar->readOnly()) {
                QString newValue = it.value().toString();
                // Avoid redundant updates and infinite loops
                if (targetVar->value() != newValue && targetVar->parsedValue() != it.value()) {
                    targetVar->setValue(newValue);
                }
            }
        }
    }

    emit isRunningChanged();
    emit hasErrorChanged();
    emit lastExecTimeChanged();
}

// ── State Persistence ────────────────────────────────────────────────────────

QJsonObject PythonBehaviour::saveState() const {
    QJsonObject s;
    s["script"] = m_script;
    s["autoRun"] = m_autoRun;
    s["timeoutMs"] = m_timeoutMs;
    return s;
}

void PythonBehaviour::loadState(const QJsonObject& s) {
    // Suppress autoRun while restoring persisted state
    m_loading = true;
    if (s.contains("script"))    setScript(s["script"].toString());
    if (s.contains("autoRun"))   setAutoRun(s["autoRun"].toBool());
    if (s.contains("timeoutMs")) setTimeoutMs(s["timeoutMs"].toInt());
    m_loading = false;
}

// ── File I/O ─────────────────────────────────────────────────────────────────

bool PythonBehaviour::loadFromFile(const QString& filePath) {
    QUrl url(filePath);
    QString actualPath = url.isLocalFile() ? url.toLocalFile() : filePath;
    
    QFile f(actualPath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }
    setScript(QString::fromUtf8(f.readAll()));
    return true;
}

bool PythonBehaviour::saveToFile(const QString& filePath) {
    QUrl url(filePath);
    QString actualPath = url.isLocalFile() ? url.toLocalFile() : filePath;
    
    QFile f(actualPath);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return false;
    }
    f.write(m_script.toUtf8());
    return true;
}
