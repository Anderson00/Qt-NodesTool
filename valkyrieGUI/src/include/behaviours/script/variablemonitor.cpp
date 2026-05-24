#include "variablemonitor.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(VariableMonitor,
    "Variable Monitor",
    "Real-time dashboard displaying selected global variables inside the workspace",
    "script", 0, 0)

VariableMonitor::VariableMonitor(QObject *parent)
    : Behaviours(parent)
{
    setWidth(260);
    setHeight(200);
    setContentHeight(200);
    setQmlBodyUrl("qrc:/behaviours/script/VariableMonitorViewer.qml");
    addInputOutputExclusion(QList<QString>({ "watchedIdsChanged()" }));
}

QMap<QString, QVariant> VariableMonitor::loadInfos() { return static_infos(); }

QMap<QString, QVariant> VariableMonitor::static_infos() {
    return QMap<QString, QVariant>({
        {"name",          "VariableMonitor"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "VariableMonitor"},
        {"desc",          "Real-time variable dashboard in the workspace"},
        {"inputs_count",  "0"},
        {"outputs_count", "0"}
    });
}

void VariableMonitor::addWatchId(const QString& id) {
    if (!id.isEmpty() && !m_watchedIds.contains(id)) {
        m_watchedIds.append(id);
        emit watchedIdsChanged();
    }
}

void VariableMonitor::removeWatchId(const QString& id) {
    if (m_watchedIds.removeOne(id))
        emit watchedIdsChanged();
}

void VariableMonitor::clearWatch() {
    if (!m_watchedIds.isEmpty()) {
        m_watchedIds.clear();
        emit watchedIdsChanged();
    }
}

QJsonObject VariableMonitor::saveState() const {
    QJsonObject s;
    QJsonArray arr;
    for (const QString& id : m_watchedIds) arr.append(id);
    s["watchedIds"] = arr;
    return s;
}

void VariableMonitor::loadState(const QJsonObject& s) {
    m_watchedIds.clear();
    if (s.contains("watchedIds")) {
        const QJsonArray arr = s["watchedIds"].toArray();
        for (const QJsonValue& v : arr) m_watchedIds.append(v.toString());
    }
    emit watchedIdsChanged();
}
