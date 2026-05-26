#include "variablemanager.h"
#include <QtQml/QQmlEngine>
#include <QUuid>
#include <QDir>
#include <QFile>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

VariableManager* VariableManager::instance() {
    // Meyers singleton: constructed once, destroyed on app exit in correct order
    static VariableManager s_instance;
    return &s_instance;
}

QObject* VariableManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*) {
    return VariableManager::instance();
}

VariableManager::VariableManager(QObject* parent) : QObject(parent) {
    // Debounce: coalesce rapid saves into a single write 500 ms after the last change
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(500);
    connect(&m_saveTimer, &QTimer::timeout, this, &VariableManager::saveToFile);

    loadFromFile();
}

QString VariableManager::variablesFilePath() const {
    const QString dir = QCoreApplication::applicationDirPath();
    QDir().mkpath(dir);
    return dir + "/variables.json";
}

QQmlListProperty<NodeVariable> VariableManager::variables() {
    return QQmlListProperty<NodeVariable>(this, &m_variables);
}

int VariableManager::count() const {
    return m_variables.size();
}

NodeVariable* VariableManager::addVariable(const QString& name, const QString& type,
                                            const QString& value, bool readOnly) {
    NodeVariable::Data d;
    d.name     = name.trimmed();
    d.type     = type;
    d.value    = value;
    d.readOnly = readOnly;
    auto* v = NodeVariable::create(d, this);
    m_variables.append(v);
    emit variablesChanged();
    autoSave();
    return v;
}

bool VariableManager::removeVariable(const QString& id) {
    for (int i = 0; i < m_variables.size(); ++i) {
        if (m_variables[i]->id() == id) {
            m_variables.takeAt(i)->deleteLater();
            emit variablesChanged();
            autoSave();
            return true;
        }
    }
    return false;
}

NodeVariable* VariableManager::variableById(const QString& id) const {
    for (NodeVariable* v : m_variables)
        if (v->id() == id) return v;
    return nullptr;
}

NodeVariable* VariableManager::variableAt(int index) const {
    if (index < 0 || index >= m_variables.size()) return nullptr;
    return m_variables.at(index);
}

void VariableManager::setVariableValue(const QString& id, const QString& value) {
    NodeVariable* v = variableById(id);
    if (!v || v->readOnly()) return;
    v->setValue(value);
    autoSave();
}

void VariableManager::setVariableReadOnly(const QString& id, bool readOnly) {
    NodeVariable* v = variableById(id);
    if (!v) return;
    v->setReadOnly(readOnly);
    autoSave();
}

QVariant VariableManager::getValue(const QString& id) const {
    NodeVariable* v = variableById(id);
    return v ? QVariant(v->value()) : QVariant();
}

QVariant VariableManager::getTypedValue(const QString& id) const {
    NodeVariable* v = variableById(id);
    return v ? v->parsedValue() : QVariant();
}

NodeVariable* VariableManager::addInt(const QString& name, int value, bool readOnly) {
    return addVariable(name, "INT", QString::number(value), readOnly);
}

NodeVariable* VariableManager::addList(const QString& name, const QString& jsonArray, bool readOnly) {
    return addVariable(name, "LIST", jsonArray, readOnly);
}

NodeVariable* VariableManager::addDict(const QString& name, const QString& jsonObject, bool readOnly) {
    return addVariable(name, "DICT", jsonObject, readOnly);
}

NodeVariable* VariableManager::addVec2(const QString& name, double x, double y, bool readOnly) {
    return addVariable(name, "VEC2", QString("%1,%2").arg(x).arg(y), readOnly);
}

NodeVariable* VariableManager::addVec3(const QString& name, double x, double y, double z, bool readOnly) {
    return addVariable(name, "VEC3", QString("%1,%2,%3").arg(x).arg(y).arg(z), readOnly);
}

void VariableManager::saveToFile() {
    QJsonArray arr;
    for (const NodeVariable* v : std::as_const(m_variables))
        arr.append(v->toJson());

    QJsonObject root;
    root["version"]   = 1;
    root["variables"] = arr;

    QFile file(variablesFilePath());
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "VariableManager: cannot write" << variablesFilePath();
        return;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    qDebug() << "[VariableManager] Saved" << arr.size() << "variable(s) ->" << variablesFilePath();
}

void VariableManager::loadFromFile() {
    QFile file(variablesFilePath());
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) return;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (doc.isNull() || !doc.isObject()) return;

    const QJsonArray arr = doc.object()["variables"].toArray();
    for (const QJsonValue& val : arr) {
        if (!val.isObject()) continue;
        NodeVariable* v = NodeVariable::fromJson(val.toObject(), this);
        if (v) m_variables.append(v);
    }

    qDebug() << "[VariableManager] Loaded" << m_variables.size() << "variable(s)";
    if (!m_variables.isEmpty())
        emit variablesChanged();
}

void VariableManager::autoSave() {
    // Restart the debounce timer; the actual write happens 500 ms after the
    // last call. Prevents thrashing when many variables are updated rapidly.
    m_saveTimer.start();
}
