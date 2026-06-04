#include "workspacemanager.h"
#include "desktopmanager.h"
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
#include <QDateTime>
#include <QUrl>
#include <QtQml/QQmlEngine>
#include <QDebug>

static constexpr int WORKSPACE_VERSION = 3;

WorkspaceManager::WorkspaceManager(QObject* parent) : QObject(parent)
{
    refreshWorkspaceList();
}

WorkspaceManager* WorkspaceManager::instance()
{
    // Meyers singleton: constructed once, destroyed on app exit in correct order
    static WorkspaceManager s_instance;
    return &s_instance;
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

QString WorkspaceManager::autosavePath(const QString& name) const
{
    return workspacesDir() + "/" + name + ".autosave.json";
}

QString WorkspaceManager::uniqueCopyName(const QString& base) const
{
    QDir dir(workspacesDir());
    QString candidate = base + "_copy";
    if (!dir.exists(candidate + ".json")) return candidate;
    for (int i = 2; i < 1000; ++i) {
        candidate = QString("%1 (%2)").arg(base).arg(i);
        if (!dir.exists(candidate + ".json")) return candidate;
    }
    return base + "_copy_" + QString::number(QDateTime::currentMSecsSinceEpoch());
}

QStringList WorkspaceManager::workspaceList()    const { return m_workspaceList; }
QString     WorkspaceManager::currentWorkspace() const { return m_currentWorkspace; }

void WorkspaceManager::refreshWorkspaceList()
{
    QDir dir(workspacesDir());
    m_workspaceList.clear();
    for (const QString& f : dir.entryList({"*.json"}, QDir::Files, QDir::Name)) {
        // Skip autosave sidecar files
        if (f.endsWith(".autosave.json")) continue;
        m_workspaceList << QFileInfo(f).baseName();
    }
    emit workspaceListChanged();
}

void WorkspaceManager::newWorkspace()
{
    if (m_viewPort) {
        m_viewPort->clearBehaviours();
        m_viewPort->undoStack()->clear();
    }
    DesktopManager::instance()->clearAll();
    m_currentWorkspace = "";
    emit currentWorkspaceChanged();
}

// ── Shared serialization helper ───────────────────────────────────────────────

QJsonObject WorkspaceManager::buildWorkspaceJson() const
{
    Q_ASSERT(m_viewPort);
    const auto& behaviours = m_viewPort->behaviours();

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
        node["state"]  = beh->saveState();
        if (beh->hiddenInPresentation())
            node["hiddenInPresentation"] = true;
        nodes.append(node);
    }

    // Connections — iterate only outputConns to avoid duplicate entries.
    // Connection comments are preserved here for both save and autosave.
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

                const QString comment = m_viewPort->getConnectionComment(
                    outputUuid, c["outputMethod"].toString(),
                    inputUuid,  c["inputMethod"].toString());
                if (!comment.isEmpty())
                    c["comment"] = comment;

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
    root["version"]          = WORKSPACE_VERSION;
    root["nodes"]            = nodes;
    root["connections"]      = connections;
    root["viewport"]         = viewport;
    root["desktops"]         = DesktopManager::instance()->serialize();
    root["pinnedNodes"]      = DesktopManager::instance()->serializePinned();
    root["currentDesktopId"] = DesktopManager::instance()->serializeCurrentDesktopId();
    root["stages"]           = m_viewPort->stagesToJson();
    return root;
}

// ── Save ──────────────────────────────────────────────────────────────────────

bool WorkspaceManager::saveWorkspace(const QString& name)
{
    if (!m_viewPort || name.isEmpty()) return false;

    QDir().mkpath(workspacesDir());
    qDebug() << "[WorkspaceManager] Saving workspace:" << name
             << "| nodes:" << m_viewPort->behaviours().size();

    QJsonObject root = buildWorkspaceJson();

    // ── Metadata (preserve createdAt across re-saves) ─────────────────────────
    const QString nowIso  = QDateTime::currentDateTime().toString(Qt::ISODate);
    QString createdAt = nowIso;
    {
        QFile prev(workspacePath(name));
        if (prev.exists() && prev.open(QIODevice::ReadOnly)) {
            const QJsonDocument pdoc = QJsonDocument::fromJson(prev.readAll());
            if (pdoc.isObject()) {
                const QString prevCreated = pdoc.object()["metadata"].toObject()["createdAt"].toString();
                if (!prevCreated.isEmpty()) createdAt = prevCreated;
            }
        }
    }

    QJsonObject metadata;
    metadata["createdAt"]       = createdAt;
    metadata["modifiedAt"]      = nowIso;
    metadata["nodeCount"]       = root["nodes"].toArray().size();
    metadata["connectionCount"] = root["connections"].toArray().size();
    root["metadata"] = metadata;

    QFile file(workspacePath(name));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "WorkspaceManager: cannot write" << workspacePath(name);
        return false;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    qDebug() << "[WorkspaceManager] Saved" << root["nodes"].toArray().size() << "nodes,"
             << root["connections"].toArray().size() << "connections ->" << workspacePath(name);

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
        const QString uuid = n["uuid"].toString();
        m_viewPort->addBehaviourWithUuid(
            n["path"].toString(),
            n["infos"].toObject(),
            uuid,
            n["x"].toDouble(),
            n["y"].toDouble(),
            n["width"].toDouble(),
            n["height"].toDouble(),
            n["title"].toString(),
            n.contains("state") ? n["state"].toObject() : QJsonObject()
        );
        if (n.value("hiddenInPresentation").toBool(false)) {
            if (Behaviours* beh = m_viewPort->searchBehaviourFromUUID(uuid))
                beh->setHiddenInPresentation(true);
        }
    }

    for (const QJsonValue& v : connArr) {
        const QJsonObject c = v.toObject();
        m_viewPort->addConnectionByUuids(
            c["outputUuid"].toString(),
            c["outputMethod"].toString(),
            c["inputUuid"].toString(),
            c["inputMethod"].toString()
        );

        if (c.contains("comment")) {
            m_viewPort->setConnectionComment(
                c["outputUuid"].toString(),
                c["outputMethod"].toString(),
                c["inputUuid"].toString(),
                c["inputMethod"].toString(),
                c["comment"].toString()
            );
        }
    }

    const QJsonObject vp = root["viewport"].toObject();
    m_viewPort->restoreViewport(vp["x"].toDouble(0), vp["y"].toDouble(0), vp["scale"].toDouble(1.0));

    // Desktops (workspace schema v3+). Legacy projects without this block fall
    // back to a single auto-created desktop containing every node.
    if (root.contains("desktops")) {
        DesktopManager::instance()->deserialize(
            root.value("desktops").toArray(),
            root.value("pinnedNodes").toArray(),
            root.value("currentDesktopId").toString());
    } else {
        // Legacy: synthesize a single desktop containing every node we just loaded
        DesktopManager::instance()->clearAll();
        for (const QJsonValue& nv : nodeArr) {
            const QString uuid = nv.toObject().value("uuid").toString();
            if (!uuid.isEmpty())
                DesktopManager::instance()->registerNewNode(uuid);
        }
    }

    // Presentation stages (optional — only present in workspaces saved after
    // the stages feature shipped). Restored after nodes/desktops so the QML
    // layer can render the StageBar with up-to-date data.
    if (root.contains("stages"))
        m_viewPort->stagesFromJson(root.value("stages").toArray());

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
        // Remove the autosave sidecar too, so it cannot accidentally be loaded
        // if a new workspace with the same name is created later.
        QFile::remove(autosavePath(name));

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
    if (QFile::exists(workspacePath(newName))) {
        qWarning() << "WorkspaceManager: rename target already exists:" << newName;
        return false;
    }
    const bool ok = QFile::rename(workspacePath(oldName), workspacePath(newName));
    if (ok) {
        // Move autosave sidecar along with the workspace
        if (QFile::exists(autosavePath(oldName)))
            QFile::rename(autosavePath(oldName), autosavePath(newName));
        if (m_currentWorkspace == oldName) {
            m_currentWorkspace = newName;
            emit currentWorkspaceChanged();
        }
        refreshWorkspaceList();
        emit workspaceRenamed(oldName, newName);
    }
    return ok;
}

// ── Duplicate ─────────────────────────────────────────────────────────────────

bool WorkspaceManager::duplicateWorkspace(const QString& name)
{
    if (name.isEmpty()) return false;
    if (!QFile::exists(workspacePath(name))) {
        qWarning() << "WorkspaceManager: source workspace not found:" << name;
        return false;
    }
    const QString newName = uniqueCopyName(name);
    if (!QFile::copy(workspacePath(name), workspacePath(newName))) {
        qWarning() << "WorkspaceManager: cannot duplicate" << name << "->" << newName;
        return false;
    }
    refreshWorkspaceList();
    emit workspaceDuplicated(newName);
    qDebug() << "[WorkspaceManager] Duplicated" << name << "->" << newName;
    return true;
}

// ── Workspace metadata ────────────────────────────────────────────────────────

QVariantMap WorkspaceManager::getWorkspaceInfo(const QString& name) const
{
    QVariantMap info;
    info["name"] = name;
    info["exists"] = false;

    const QString path = workspacePath(name);
    QFileInfo fi(path);
    if (!fi.exists()) return info;

    info["exists"]       = true;
    info["filePath"]     = path;
    info["fileSize"]     = fi.size();
    info["fileModified"] = fi.lastModified().toString(Qt::ISODate);

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return info;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) return info;

    const QJsonObject root = doc.object();
    const QJsonObject meta = root["metadata"].toObject();

    // Prefer metadata block when available; fall back to counting arrays
    const int nodeCount = meta.contains("nodeCount")
            ? meta["nodeCount"].toInt()
            : root["nodes"].toArray().size();
    const int connCount = meta.contains("connectionCount")
            ? meta["connectionCount"].toInt()
            : root["connections"].toArray().size();

    info["version"]         = root["version"].toInt(1);
    info["nodeCount"]       = nodeCount;
    info["connectionCount"] = connCount;
    info["createdAt"]       = meta["createdAt"].toString();
    info["modifiedAt"]      = meta["modifiedAt"].toString(info["fileModified"].toString());
    info["description"]     = meta["description"].toString();
    info["hasAutosave"]     = QFile::exists(autosavePath(name));

    return info;
}

// ── Export / Import ───────────────────────────────────────────────────────────

bool WorkspaceManager::exportWorkspace(const QString& name, const QString& filePath)
{
    if (name.isEmpty() || filePath.isEmpty()) return false;
    QString dest = filePath;
    // Allow file:/// URLs coming from QML FileDialog
    if (dest.startsWith("file:///")) dest = QUrl(dest).toLocalFile();
    if (QFile::exists(dest)) QFile::remove(dest);
    const bool ok = QFile::copy(workspacePath(name), dest);
    if (!ok)
        qWarning() << "WorkspaceManager: export failed" << name << "->" << dest;
    return ok;
}

bool WorkspaceManager::importWorkspace(const QString& filePath)
{
    if (filePath.isEmpty()) return false;
    QString src = filePath;
    if (src.startsWith("file:///")) src = QUrl(src).toLocalFile();
    QFileInfo fi(src);
    if (!fi.exists()) return false;

    QDir().mkpath(workspacesDir());
    QString base = fi.completeBaseName();
    if (base.endsWith(".autosave")) base.chop(QString(".autosave").size());

    QString target = base;
    if (QFile::exists(workspacePath(target)))
        target = uniqueCopyName(base);

    const bool ok = QFile::copy(src, workspacePath(target));
    if (ok) refreshWorkspaceList();
    return ok;
}

// ── Autosave ──────────────────────────────────────────────────────────────────

bool WorkspaceManager::saveAutosave()
{
    if (!m_viewPort || m_currentWorkspace.isEmpty()) return false;
    QDir().mkpath(workspacesDir());

    // Reuse buildWorkspaceJson() so the autosave is always in sync with
    // saveWorkspace() — previously this was duplicated code and had diverged
    // (connection comments were lost in autosave).
    QJsonObject root = buildWorkspaceJson();

    QJsonObject metadata;
    metadata["modifiedAt"]      = QDateTime::currentDateTime().toString(Qt::ISODate);
    metadata["nodeCount"]       = root["nodes"].toArray().size();
    metadata["connectionCount"] = root["connections"].toArray().size();
    metadata["autosave"]        = true;
    root["metadata"] = metadata;

    QFile file(autosavePath(m_currentWorkspace));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning() << "WorkspaceManager: cannot write autosave" << autosavePath(m_currentWorkspace);
        return false;
    }
    file.write(QJsonDocument(root).toJson(QJsonDocument::Compact));
    return true;
}

bool WorkspaceManager::hasAutosave(const QString& name) const
{
    if (name.isEmpty()) return false;
    QFileInfo autosave(autosavePath(name));
    if (!autosave.exists()) return false;
    QFileInfo main(workspacePath(name));
    // Autosave is meaningful only if it's strictly newer than the saved workspace
    if (!main.exists()) return true;
    return autosave.lastModified() > main.lastModified();
}

bool WorkspaceManager::loadAutosave(const QString& name)
{
    if (!m_viewPort) return false;
    QFile file(autosavePath(name));
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) return false;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) return false;

    const QJsonObject root  = doc.object();
    const QJsonArray nodeArr = root["nodes"].toArray();
    const QJsonArray connArr = root["connections"].toArray();

    m_viewPort->clearBehaviours();

    for (const QJsonValue& v : nodeArr) {
        const QJsonObject n = v.toObject();
        const QString uuid = n["uuid"].toString();
        m_viewPort->addBehaviourWithUuid(
            n["path"].toString(),
            n["infos"].toObject(),
            uuid,
            n["x"].toDouble(),
            n["y"].toDouble(),
            n["width"].toDouble(),
            n["height"].toDouble(),
            n["title"].toString(),
            n.contains("state") ? n["state"].toObject() : QJsonObject()
        );
        if (n.value("hiddenInPresentation").toBool(false)) {
            if (Behaviours* beh = m_viewPort->searchBehaviourFromUUID(uuid))
                beh->setHiddenInPresentation(true);
        }
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

    if (root.contains("desktops")) {
        DesktopManager::instance()->deserialize(
            root.value("desktops").toArray(),
            root.value("pinnedNodes").toArray(),
            root.value("currentDesktopId").toString());
    } else {
        DesktopManager::instance()->clearAll();
        for (const QJsonValue& nv : nodeArr) {
            const QString uuid = nv.toObject().value("uuid").toString();
            if (!uuid.isEmpty())
                DesktopManager::instance()->registerNewNode(uuid);
        }
    }

    // Restore presentation stages (same as loadWorkspace).
    if (root.contains("stages"))
        m_viewPort->stagesFromJson(root.value("stages").toArray());

    if (m_currentWorkspace != name) {
        m_currentWorkspace = name;
        emit currentWorkspaceChanged();
    }
    emit workspaceLoaded(name);
    return true;
}

bool WorkspaceManager::clearAutosave(const QString& name)
{
    const QString p = autosavePath(name);
    if (!QFile::exists(p)) return true;
    return QFile::remove(p);
}
