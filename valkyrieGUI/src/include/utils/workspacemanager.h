#ifndef WORKSPACEMANAGER_H
#define WORKSPACEMANAGER_H

#include <QObject>
#include <QStringList>

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

signals:
    void workspaceListChanged();
    void currentWorkspaceChanged();
    void workspaceLoaded(const QString& name);

private:
    explicit WorkspaceManager(QObject* parent = nullptr);
    QString workspacesDir() const;
    QString workspacePath(const QString& name) const;

    ViewPortWindow* m_viewPort = nullptr;
    QStringList     m_workspaceList;
    QString         m_currentWorkspace;
};

#endif // WORKSPACEMANAGER_H
