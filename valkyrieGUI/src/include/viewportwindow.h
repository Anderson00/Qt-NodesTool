#ifndef VIEWPORTWINDOW_H
#define VIEWPORTWINDOW_H

#include <QObject>
#include <QTimer>
#include <QHash>
#include <QWidget>
#include <QJsonObject>
#include <QJsonArray>
#include <QList>
#include <QVariantList>
#include <QUndoStack>
#include "behaviours/behaviours.h"
#include "presentation/PresentationStage.h"
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

    Q_PROPERTY(int historyCount READ historyCount NOTIFY historyChanged)
    Q_PROPERTY(int historyIndex READ historyIndex NOTIFY historyChanged)

    Q_PROPERTY(int presentationMode READ presentationMode WRITE setPresentationMode NOTIFY presentationModeChanged)

    // Presentation stages — named camera framings the user can navigate to.
    Q_PROPERTY(int  stageCount   READ stageCount   NOTIFY stagesChanged)
    Q_PROPERTY(int  currentStage READ currentStage WRITE setCurrentStage NOTIFY currentStageChanged)
    Q_PROPERTY(bool hasStages    READ hasStages    NOTIFY stagesChanged)

public:
    enum PresentationLayer {
        PresentationOff    = 0,
        PresentationQuiet  = 1,
        PresentationLocked = 2
    };
    Q_ENUM(PresentationLayer)

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
    int   historyCount()  const;
    int   historyIndex()  const;

    int   presentationMode() const;
    Q_INVOKABLE void setPresentationMode(int mode);

    // ── Presentation stages ──────────────────────────────────────────────
    int  stageCount()   const;
    int  currentStage() const;
    bool hasStages()    const;
    // Q_INVOKABLE so QML can call viewPort.setCurrentStage(n) as a method —
    // being just the WRITE of a Q_PROPERTY only exposes assignment, not the
    // function call form used by the F5/Shift+F5 shortcuts and StageBar.
    Q_INVOKABLE void setCurrentStage(int idx);
    // Re-emits stageTransitionRequested for the current stage. Used by the
    // presentation entry timer so the very first F10 -> stage 0 transition
    // still animates even when m_currentStage is already 0.
    Q_INVOKABLE void replayCurrentStage();

    Q_INVOKABLE QString      addStage(const QString& name,
                                      qreal x, qreal y, qreal w, qreal h,
                                      qreal zoom = -1);
    Q_INVOKABLE void         removeStage(const QString& id);
    Q_INVOKABLE void         updateStage(const QString& id,
                                         const QString& name,
                                         const QString& notes);
    Q_INVOKABLE void         moveStage(int from, int to);
    Q_INVOKABLE QVariantList stagesData() const;

    // Serialization helpers used by WorkspaceManager (save / load).
    QJsonArray stagesToJson() const;
    void       stagesFromJson(const QJsonArray& arr);

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

    Q_INVOKABLE bool addPythonNodeWithScript(const QString& filePath, double x, double y);

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
    Q_INVOKABLE QString historyText(int index) const;
    Q_INVOKABLE void    jumpToHistory(int index);

    Q_INVOKABLE void recordNodeMove(const QString& uuid,
                                    double oldX, double oldY, double newX, double newY);
    Q_INVOKABLE void recordNodeResize(const QString& uuid,
                                      double oldX, double oldY, double oldW, double oldH,
                                      double newX, double newY, double newW, double newH);
    Q_INVOKABLE void beginUndoMacro(const QString& text);
    Q_INVOKABLE void endUndoMacro();

    // Copy / paste
    Q_INVOKABLE QVariantMap getNodeData(const QString& uuid) const;
    Q_INVOKABLE QString     pasteNode(const QVariantMap& data, double offsetX, double offsetY);

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

    // Port compatibility check — used by QML for drag-connect visual highlighting.
    // srcSig is the signal (output) method signature, dstSig is the slot (input).
    // Returns true for exact matches and all registered coercion pairs.
    Q_INVOKABLE bool isPortCompatible(const QString& srcSig, const QString& dstSig) const;

    // Extended compatibility check that also validates PinType semantics.
    // srcUuid / dstUuid are the node UUIDs; srcSig / dstSig the method signatures.
    // If either UUID is unknown, falls back to the signature-only check.
    Q_INVOKABLE bool isPortCompatibleFull(const QString& srcUuid, const QString& srcSig,
                                          const QString& dstUuid, const QString& dstSig) const;

    void restoreViewport(qreal x, qreal y, qreal scale);

signals:
    void fullScreenToogle();
    // Emitted whenever the presentation mode changes — MainWindow listens to
    // toggle the OS-level window between fullscreen and the previous state.
    // active=true → enter fullscreen; active=false → restore.
    void presentationFullScreenRequested(bool active);
    void showFpsChanged();
    void fpsCountChanged();
    void viewportStateChanged();
    void undoStateChanged();
    void historyChanged();
    void presentationModeChanged();
    void stagesChanged();
    void currentStageChanged();
    // Emitted when setCurrentStage() runs — the QML layer animates the
    // canvas pan/zoom to frame the requested world rectangle. zoom < 0
    // means "auto-fit the rectangle in the viewport".
    void stageTransitionRequested(qreal worldX, qreal worldY,
                                  qreal worldW, qreal worldH,
                                  qreal zoom);
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
    int   m_presentationMode = 0;

    QList<PresentationStage*> m_stages;
    int  m_currentStage = -1;
};

#endif // VIEWPORTWINDOW_H
