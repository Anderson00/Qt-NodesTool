#ifndef VIEWPORTWINDOW_H
#define VIEWPORTWINDOW_H

#include <QObject>
#include <QTimer>
#include <QHash>
#include <QWidget>
#include "behaviours/behaviours.h"
#include "qmlwindow.h"

class ViewPortWindow : public QMLWindow
{
    Q_OBJECT
    Q_PROPERTY(QHash<QString, Behaviours*> behaviours READ behaviours NOTIFY behaviourAdded)
    Q_PROPERTY(bool showFps READ showFps NOTIFY showFpsChanged)
    Q_PROPERTY(int fpsCount READ fpsCount NOTIFY fpsCountChanged)
public:
    explicit ViewPortWindow(QWidget *parent = nullptr);
    ~ViewPortWindow();

    QHash<QString, Behaviours*> behaviours();
    bool showFps();
    int fpsCount();
    void setFpsCount(int value);

public slots:
    void setFullScreen(bool isFull);
    bool addBehaviour(const QString &path, const QJsonObject infos);
    bool removeBehaviourFromUUID(const QString &uuid);
    bool removeBehaviourObject(Behaviours * object);
    void setShowFps(bool state);

    Behaviours* searchBehaviourFromUUID(const QString &uuid);
    QString getUUIDFromBehaviour(Behaviours * object);

signals:
    void fullScreenToogle();
    void showFpsChanged();
    void fpsCountChanged();
    void behaviourAdded(Behaviours *behaviour);
    void behaviourConnection(Behaviours *source, Behaviours *target);

private:
    //    UUID  , Behaviour
    QHash<QString, Behaviours*> m_behaviours;

    QTimer *m_frameTimer = nullptr;
    QMetaObject::Connection m_timerTriggerConn;
    QMetaObject::Connection m_frameSwappedConn;
    bool m_showFps = false;
    int m_fpsCount = 0;
    int m_frameCount = 0;
};

#endif // VIEWPORTWINDOW_H
