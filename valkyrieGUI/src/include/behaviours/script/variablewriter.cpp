#include "variablewriter.h"
#include "behaviours/behaviourregistry.h"
#include "model/variablemanager.h"
#include "model/nodevariable.h"

REGISTER_BEHAVIOUR(VariableWriter,
    "Variable Writer",
    "Write an incoming value into a global variable",
    "script", 3, 0)

VariableWriter::VariableWriter(QObject *parent)
    : Behaviours(parent)
{
    setWidth(220);
    setHeight(130);
    setContentHeight(130);
    setQmlBodyUrl("qrc:/behaviours/script/VariableWriterViewer.qml");
    addInputOutputExclusion(QList<QString>({
        "selectedIdChanged()",
        "lastValueChanged()"
    }));
}

QMap<QString, QVariant> VariableWriter::loadInfos() { return static_infos(); }

QMap<QString, QVariant> VariableWriter::static_infos() {
    return QMap<QString, QVariant>({
        {"name",          "VariableWriter"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "VariableWriter"},
        {"desc",          "Write a value into a global variable"},
        {"inputs_count",  "3"},
        {"outputs_count", "0"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QString VariableWriter::selectedName() const {
    NodeVariable* v = VariableManager::instance()->variableById(m_selectedId);
    return v ? v->name() : QString();
}

QString VariableWriter::currentType() const {
    NodeVariable* v = VariableManager::instance()->variableById(m_selectedId);
    return v ? v->type() : QString();
}

// ── Slots ────────────────────────────────────────────────────────────────────

void VariableWriter::setSelectedId(const QString& id) {
    if (m_selectedId == id) return;
    m_selectedId = id;
    emit selectedIdChanged();
}

void VariableWriter::setInput(double value) {
    writeValue(QString::number(value));
}

void VariableWriter::setText(const QString& value) {
    writeValue(value);
}

void VariableWriter::setBool(bool value) {
    writeValue(value ? "true" : "false");
}

// ── Core ─────────────────────────────────────────────────────────────────────

void VariableWriter::writeValue(const QString& serialised) {
    if (m_selectedId.isEmpty()) return;
    VariableManager::instance()->setVariableValue(m_selectedId, serialised);
    m_lastValue = serialised;
    emit lastValueChanged();
}

// ── State ────────────────────────────────────────────────────────────────────

QJsonObject VariableWriter::saveState() const {
    QJsonObject s;
    s["selectedId"] = m_selectedId;
    return s;
}

void VariableWriter::loadState(const QJsonObject& s) {
    if (s.contains("selectedId")) setSelectedId(s["selectedId"].toString());
}
