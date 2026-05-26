#include "variablereader.h"
#include "behaviours/behaviourregistry.h"
#include "model/variablemanager.h"
#include "model/nodevariable.h"

REGISTER_BEHAVIOUR(VariableReader,
    "Variable Reader",
    "Read a global variable and emit its value into the graph",
    "script", 0, 3)

VariableReader::VariableReader(QObject *parent)
    : Behaviours(parent)
{
    setWidth(220);
    setHeight(130);
    setContentHeight(130);
    setQmlBodyUrl("qrc:/behaviours/script/VariableReaderViewer.qml");
    addInputOutputExclusion(QList<QString>({
        "selectedIdChanged()",
        "currentValueChanged()"
    }));

    // React to any variable change in the manager
    connect(VariableManager::instance(), &VariableManager::variablesChanged,
            this, &VariableReader::onVariablesChanged);
}

void VariableReader::onPinsReady()
{
    // outputs
    setPinTypeForSignature("outputValue(double)", Connections::DoubleType);
    setPinTypeForSignature("outputText(QString)", Connections::StringType);
    setPinTypeForSignature("outputBool(bool)",    Connections::BoolType);
}

QMap<QString, QVariant> VariableReader::loadInfos() { return static_infos(); }

QMap<QString, QVariant> VariableReader::static_infos() {
    return QMap<QString, QVariant>({
        {"name",          "VariableReader"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "VariableReader"},
        {"desc",          "Read a global variable and emit into the graph"},
        {"inputs_count",  "0"},
        {"outputs_count", "3"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QString VariableReader::selectedName() const {
    NodeVariable* v = VariableManager::instance()->variableById(m_selectedId);
    return v ? v->name() : QString();
}

QString VariableReader::currentType() const {
    NodeVariable* v = VariableManager::instance()->variableById(m_selectedId);
    return v ? v->type() : QString();
}

// ── Slots ────────────────────────────────────────────────────────────────────

void VariableReader::setSelectedId(const QString& id) {
    if (m_selectedId == id) return;
    m_selectedId = id;
    emit selectedIdChanged();
    emitCurrentValue();
}

void VariableReader::onVariablesChanged() {
    // The selected variable may have changed its value
    emitCurrentValue();
    emit selectedIdChanged();  // refresh name/type display
}

// ── Core ─────────────────────────────────────────────────────────────────────

void VariableReader::emitCurrentValue() {
    NodeVariable* v = VariableManager::instance()->variableById(m_selectedId);
    if (!v) return;

    m_currentValue = v->value();
    emit currentValueChanged();

    // Emit typed outputs
    bool ok;
    double numVal = m_currentValue.toDouble(&ok);
    if (ok) emit outputValue(numVal);
    emit outputText(m_currentValue);
    emit outputBool(m_currentValue == "true");
}

// ── State ────────────────────────────────────────────────────────────────────

QJsonObject VariableReader::saveState() const {
    QJsonObject s;
    s["selectedId"] = m_selectedId;
    return s;
}

void VariableReader::loadState(const QJsonObject& s) {
    if (s.contains("selectedId")) setSelectedId(s["selectedId"].toString());
}
