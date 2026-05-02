#ifndef VIEWPORTWINDOW_H
#define VIEWPORTWINDOW_H

#include <QObject>
#include <QTimer>
#include <QHash>
#include <QWidget>
#include <QJsonObject>
#include <QVariantList>
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

public:
    explicit ViewPortWindow(QWidget* parent = nullptr);
    ~ViewPortWindow();

    QHash<QString, Behaviours*> behaviours();
    bool  showFps()       const;
    int   fpsCount()      const;
    qreal viewportX()     const;
    qreal viewportY()     const;
    qreal viewportScale() const;

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
                               const QString& title);

    bool removeBehaviourFromUUID(const QString& uuid);
    bool removeBehaviourObject(Behaviours* object);
    void clearBehaviours();

    Behaviours* searchBehaviourFromUUID(const QString& uuid);
    QString     getUUIDFromBehaviour(Behaviours* object);

    // Connection management
    bool addConnectionByUuids(const QString& outputUuid, const QString& outputMethod,
                               const QString& inputUuid,  const QString& inputMethod);

    // Workspace
    Q_INVOKABLE bool saveWorkspace(const QString& name);
    Q_INVOKABLE bool loadWorkspace(const QString& name);
    Q_INVOKABLE QVariantList getAllConnections() const;

    void restoreViewport(qreal x, qreal y, qreal scale);

signals:
    void fullScreenToogle();
    void showFpsChanged();
    void fpsCountChanged();
    void viewportStateChanged();
    void viewportRestoreRequested(qreal x, qreal y, qreal scale);
    void behaviourAdded(Behaviours* behaviour);
    void behavioursCleared();
    void behaviourConnection(Behaviours* source, Behaviours* target);

private:
    void connectBehaviour(Behaviours* object);

    QHash<QString, Behaviours*> m_behaviours;

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
