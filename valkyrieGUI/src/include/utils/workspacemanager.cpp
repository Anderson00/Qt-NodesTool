#include "workspacemanager.h"
#include "../viewportwindow.h"
#include "../behaviours/behaviours.h"
#include "../behaviours/connections.h"
#include "../model/connectionmodel.h"

#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QtQml/QQmlEngine>
#include <QDebug>

WorkspaceManager::WorkspaceManager(QObject* parent) : QObject(parent)
{
    refreshWorkspaceList();
}

WorkspaceManager* WorkspaceManager::instance()
{
    static WorkspaceManager* _instance = new WorkspaceManager();
    return _instance;
}

QObject* WorkspaceManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*)
{
    return WorkspaceManager::instance();
}

void WorkspaceManager::setViewPort(ViewPortWindow* vp)
{
    m_viewPort = vp;
}

QString WorkspaceManager::workspacesDir() const
{
    return QCoreApplication::applicationDirPath() + "/workspaces";
}

QString WorkspaceManager::workspacePath(const QString& name) const
{
    return workspacesDir() + "/" + name + ".json";
}

QStringList WorkspaceManager::workspaceList()    const { return m_workspaceList; }
QString     WorkspaceManager::currentWorkspace() const { return m_currentWorkspace; }

void WorkspaceManager::refreshWorkspaceList()
{
    QDir dir(workspacesDir());
    m_workspaceList.clear();
    for (const QString& f : dir.entryList({"*.json"}, QDir::Files, QDir::Name))
        m_workspaceList << QFileInfo(f).baseName();
    emit workspaceListChanged();
}

// ── Save ──────────────────────────────────────────────────────────────────────

bool WorkspaceManager::saveWorkspace(const QString& name)
{
    if (!m_viewPort || name.isEmpty()) return false;

    QDir().mkpath(workspacesDir());

    const auto& behaviours = m_viewPort->behaviours();
    qDebug() << "[WorkspaceManager] Saving workspace:" << name
             << "| nodes:" << behaviours.size();

    // Nodes
    QJsonArray nodes;
    for (auto it = behaviours.constBegin(); it != behaviours.constEnd(); ++it) {
        Behaviours* beh = it.value();
        QJsonObject node;
        node["uuid"]   = it.key();
        node["path"]   = beh->behaviourPath();
        node["infos"]  = beh->behaviourInfos();
        node["x"]      = beh->x();
        node["y"]      = beh->y();
        node["width"]  = beh->width();
        node["height"] = beh->height();
        node["title"]  = beh->title();
        nodes.append(node);
    }

    // Connections — iterate only outputConns to avoid duplicate entries
    QJsonArray connections;
    for (auto it = behaviours.constBegin(); it != behaviours.constEnd(); ++it) {
        const QString& outputUuid = it.key();
        const auto& outs = it.value()->outputConns();
        for (auto ci = outs.constBegin(); ci != outs.constEnd(); ++ci) {
            Connections* conn = ci.value();
            for (ConnectionModel* model : conn->getAllConnections()) {
                const QString inputUuid = m_viewPort->getUUIDFromBehaviour(model->input());
                if (inputUuid.isEmpty()) continue;
                QJsonObject c;
                c["outputUuid"]   = outputUuid;
                c["outputMethod"] = conn->methodSignature();
                c["inputUuid"]    = inputUuid;
                c["inputMethod"]  = QString::fromLatin1(model->slot().methodSignature());
                connections.append(c);
            }
        }
    }

    // Viewport state
    QJsonObject viewport;
    viewport["x"]     = m_viewPort->viewportX();
    viewport["y"]     = m_viewPort->viewportY();
    viewport["scale"] = m_viewPort->viewportScale();

    QJsonObject root;
    root["version"]     = 1;
    root["nodes"]       = nodes;
    root["connections"] = connections;
    root["viewport"]    = viewport;

    QFile file(workspacePath(name));

    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "WorkspaceManager: cannot write" << workspacePath(name);
        return false;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    qDebug() << "[WorkspaceManager] Saved" << nodes.size() << "nodes,"
             << connections.size() << "connections ->" << workspacePath(name);

    if (m_currentWorkspace != name) {
        m_currentWorkspace = name;
        emit currentWorkspaceChanged();
    }
    refreshWorkspaceList();
    return true;
}

// ── Load ──────────────────────────────────────────────────────────────────────

bool WorkspaceManager::loadWorkspace(const QString& name)
{
    if (!m_viewPort) return false;

    QFile file(workspacePath(name));
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) {
        qWarning() << "WorkspaceManager: cannot read" << workspacePath(name);
        return false;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (doc.isNull() || !doc.isObject()) {
        qWarning() << "WorkspaceManager: malformed JSON in" << name;
        return false;
    }

    const QJsonObject root = doc.object();

    const QJsonArray nodeArr = root["nodes"].toArray();
    const QJsonArray connArr = root["connections"].toArray();
    qDebug() << "[WorkspaceManager] Loading workspace:" << name
             << "| nodes:" << nodeArr.size() << "| connections:" << connArr.size();

    m_viewPort->clearBehaviours();

    for (const QJsonValue& v : nodeArr) {
        const QJsonObject n = v.toObject();
        m_viewPort->addBehaviourWithUuid(
            n["path"].toString(),
            n["infos"].toObject(),
            n["uuid"].toString(),
            n["x"].toDouble(),
            n["y"].toDouble(),
            n["width"].toDouble(),
            n["height"].toDouble(),
            n["title"].toString()
        );
    }

    for (const QJsonValue& v : connArr) {
        const QJsonObject c = v.toObject();
        m_viewPort->addConnectionByUuids(
            c["outputUuid"].toString(),
            c["outputMethod"].toString(),
            c["inputUuid"].toString(),
            c["inputMethod"].toString()
        );
    }

    const QJsonObject vp = root["viewport"].toObject();
    m_viewPort->restoreViewport(vp["x"].toDouble(0), vp["y"].toDouble(0), vp["scale"].toDouble(1.0));

    qDebug() << "[WorkspaceManager] Workspace loaded successfully:" << name;
    emit workspaceLoaded(name);

    if (m_currentWorkspace != name) {
        m_currentWorkspace = name;
        emit currentWorkspaceChanged();
    }
    return true;
}

// ── Delete / Rename ───────────────────────────────────────────────────────────

bool WorkspaceManager::deleteWorkspace(const QString& name)
{
    const bool ok = QFile::remove(workspacePath(name));
    if (ok) {
        if (m_currentWorkspace == name) {
            m_currentWorkspace.clear();
            emit currentWorkspaceChanged();
        }
        refreshWorkspaceList();
    }
    return ok;
}

bool WorkspaceManager::renameWorkspace(const QString& oldName, const QString& newName)
{
    if (newName.isEmpty() || oldName == newName) return false;
    const bool ok = QFile::rename(workspacePath(oldName), workspacePath(newName));
    if (ok) {
        if (m_currentWorkspace == oldName) {
            m_currentWorkspace = newName;
            emit currentWorkspaceChanged();
        }
        refreshWorkspaceList();
    }
    return ok;
}
