#ifndef VIEWPORTWINDOW_H
#define VIEWPORTWINDOW_H

#include <QObject>
#include <QTimer>
#include <QHash>
#include <QWidget>
#include <QJsonObject>
#include <QVariantList>
#include <QUndoStack>
#include "behaviours/behaviours.h"
#include "qmlwindow.h"

class ViewPortWindow : public QMLWindow
{
    Q_OBJECT

    Q_PROPERTY(QHash<QString, Behaviours*> behaviours READ behaviours NOTIFY behaviourAdded)
    Q_PROPERTY(bool showFps    READ showFps    NOTIFY showFpsChanged)
    Q_PROPERTY(int  fpsCount   READ fpsCount   NOTIFY fpsCountChanged)

    // Viewport pan/zoom — set from QML, read by WorkspaceManager
    Q_PROPERTY(qreal viewportX     READ viewportX     WRITE setViewportX     NOTIFY viewportStateChanged)
    Q_PROPERTY(qreal viewportY     READ viewportY     WRITE setViewportY     NOTIFY viewportStateChanged)
    Q_PROPERTY(qreal viewportScale READ viewportScale WRITE setViewportScale NOTIFY viewportStateChanged)

    Q_PROPERTY(bool canUndo  READ canUndo  NOTIFY undoStateChanged)
    Q_PROPERTY(bool canRedo  READ canRedo  NOTIFY undoStateChanged)
    Q_PROPERTY(bool isClean  READ isClean  NOTIFY undoStateChanged)

public:
    explicit ViewPortWindow(QWidget* parent = nullptr);
    ~ViewPortWindow();

    QHash<QString, Behaviours*> behaviours();
    bool  showFps()       const;
    int   fpsCount()      const;
    qreal viewportX()     const;
    qreal viewportY()     const;
    qreal viewportScale() const;
    bool  canUndo()       const;
    bool  canRedo()       const;
    bool  isClean()       const;

    QUndoStack* undoStack() const;

    void setFpsCount(int value);
    void setViewportX(qreal x);
    void setViewportY(qreal y);
    void setViewportScale(qreal s);

public slots:
    void setFullScreen(bool isFull);
    void setShowFps(bool state);

    // Node management
    bool addBehaviour(const QString& path, const QJsonObject infos);
    bool addBehaviourWithUuid(const QString& path, const QJsonObject& infos,
                               const QString& uuid,
                               double x, double y, double w, double h,
                               const QString& title,
                               const QJsonObject& state = QJsonObject());

    bool removeBehaviourFromUUID(const QString& uuid);
    bool removeBehaviourObject(Behaviours* object);
    void clearBehaviours();

    Behaviours* searchBehaviourFromUUID(const QString& uuid);
    QString     getUUIDFromBehaviour(Behaviours* object);

    // Connection management
    bool addConnectionByUuids(const QString& outputUuid, const QString& outputMethod,
                               const QString& inputUuid,  const QString& inputMethod);
    bool removeConnectionByUuids(const QString& outputUuid, const QString& outputMethod,
                                  const QString& inputUuid,  const QString& inputMethod);

    // Undo/redo — user-facing (push to stack)
    Q_INVOKABLE void undo();
    Q_INVOKABLE void redo();
    Q_INVOKABLE bool removeNodeWithUndo(const QString& uuid);
    Q_INVOKABLE bool addConnectionWithUndo(const QString& outputUuid, const QString& outputMethod,
                                            const QString& inputUuid,  const QString& inputMethod);
    Q_INVOKABLE bool removeConnectionWithUndo(const QString& outputUuid, const QString& outputMethod,
                                               const QString& inputUuid,  const QString& inputMethod);
    Q_INVOKABLE void recordNodeMove(const QString& uuid,
                                    double oldX, double oldY, double newX, double newY);
    Q_INVOKABLE void recordNodeResize(const QString& uuid,
                                      double oldX, double oldY, double oldW, double oldH,
                                      double newX, double newY, double newW, double newH);

    // Workspace
    Q_INVOKABLE bool saveWorkspace(const QString& name);
    Q_INVOKABLE bool loadWorkspace(const QString& name);
    Q_INVOKABLE QVariantList getAllConnections() const;
    Q_INVOKABLE QVariantList getNodeConnections(const QString& nodeUuid) const;

    // Comments
    Q_INVOKABLE void setConnectionComment(const QString& outputUuid, const QString& outputMethod,
                                          const QString& inputUuid,  const QString& inputMethod,
                                          const QString& comment);
    Q_INVOKABLE QString getConnectionComment(const QString& outputUuid, const QString& outputMethod,
                                             const QString& inputUuid,  const QString& inputMethod) const;

    // Screenshot
    Q_INVOKABLE void takeScreenshot(const QString& filePath);

    void restoreViewport(qreal x, qreal y, qreal scale);

signals:
    void fullScreenToogle();
    void showFpsChanged();
    void fpsCountChanged();
    void viewportStateChanged();
    void undoStateChanged();
    void viewportRestoreRequested(qreal x, qreal y, qreal scale);
    void behaviourAdded(Behaviours* behaviour);
    void behaviourRemoved(Behaviours* obj, const QString& uuid);
    void behavioursCleared();
    void behaviourConnection(Behaviours* source, Behaviours* target);
    void connectionAdded(const QString& outputUuid, const QString& outputMethod,
                         const QString& inputUuid,  const QString& inputMethod);
    void connectionRemoved(const QString& outputUuid, const QString& outputMethod,
                           const QString& inputUuid,  const QString& inputMethod);

private:
    void connectBehaviour(Behaviours* object);

    QHash<QString, Behaviours*> m_behaviours;
    QUndoStack* m_undoStack = nullptr;
    QHash<QString, QString> m_connectionComments;

    QTimer*  m_frameTimer = nullptr;
    QMetaObject::Connection m_timerTriggerConn;
    QMetaObject::Connection m_frameSwappedConn;
    bool  m_showFps    = false;
    int   m_fpsCount   = 0;
    int   m_frameCount = 0;
    qreal m_viewportX     = 0.0;
    qreal m_viewportY     = 0.0;
    qreal m_viewportScale = 1.0;
};

#endif // VIEWPORTWINDOW_H
