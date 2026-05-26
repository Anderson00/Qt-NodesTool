#ifndef WORKSPACEMANAGER_H
#define WORKSPACEMANAGER_H

#include <QObject>
#include <QStringList>
#include <QVariantMap>

class ViewPortWindow;
class QQmlEngine;
class QJSEngine;

class WorkspaceManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList workspaceList    READ workspaceList    NOTIFY workspaceListChanged)
    Q_PROPERTY(QString     currentWorkspace READ currentWorkspace NOTIFY currentWorkspaceChanged)

public:
    static WorkspaceManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    QStringList workspaceList()    const;
    QString     currentWorkspace() const;

    void setViewPort(ViewPortWindow* vp);

public slots:
    bool saveWorkspace(const QString& name);
    bool loadWorkspace(const QString& name);
    bool deleteWorkspace(const QString& name);
    bool renameWorkspace(const QString& oldName, const QString& newName);
    void refreshWorkspaceList();
    Q_INVOKABLE void    newWorkspace();
    Q_INVOKABLE bool    duplicateWorkspace(const QString& name);
    Q_INVOKABLE QVariantMap getWorkspaceInfo(const QString& name) const;
    Q_INVOKABLE bool    exportWorkspace(const QString& name, const QString& filePath);
    Q_INVOKABLE bool    importWorkspace(const QString& filePath);
    Q_INVOKABLE bool    saveAutosave();
    Q_INVOKABLE bool    hasAutosave(const QString& name) const;
    Q_INVOKABLE bool    loadAutosave(const QString& name);
    Q_INVOKABLE bool    clearAutosave(const QString& name);

signals:
    void workspaceListChanged();
    void currentWorkspaceChanged();
    void workspaceLoaded(const QString& name);
    void workspaceRenamed(const QString& oldName, const QString& newName);
    void workspaceDuplicated(const QString& newName);

private:
    explicit WorkspaceManager(QObject* parent = nullptr);
    QString workspacesDir() const;
    QString workspacePath(const QString& name) const;
    QString autosavePath(const QString& name) const;
    QString uniqueCopyName(const QString& base) const;

    // Shared serialization logic (nodes + connections with comments + viewport +
    // desktops). Both saveWorkspace() and saveAutosave() call this to avoid drift.
    QJsonObject buildWorkspaceJson() const;

    ViewPortWindow* m_viewPort = nullptr;
    QStringList     m_workspaceList;
    QString         m_currentWorkspace;
};

#endif // WORKSPACEMANAGER_H
