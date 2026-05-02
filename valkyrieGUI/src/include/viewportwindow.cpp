#include "viewportwindow.h"
#include "behaviours/behaviourloader.h"
#include "behaviours/connections.h"
#include "model/connectionmodel.h"
#include "utils/workspacemanager.h"
#include <QUuid>
#include <QVariantMap>

ViewPortWindow::ViewPortWindow(QWidget* parent)
    : QMLWindow(parent, QUrl("qrc:/subwindows/ViewPortWindow.qml"))
{
    m_frameTimer = new QTimer(this);
    m_frameTimer->setTimerType(Qt::PreciseTimer);
    m_frameTimer->setInterval(1000);

    showWindow(QVector<QMLWindow::PropertyPair>({
        { "viewPort",        this },
        { "behaviourLoader", BehaviourLoader::instance() }
    }));

    WorkspaceManager::instance()->setViewPort(this);
}

ViewPortWindow::~ViewPortWindow() {}

// ── Properties ────────────────────────────────────────────────────────────────

QHash<QString, Behaviours*> ViewPortWindow::behaviours() { return m_behaviours; }
bool  ViewPortWindow::showFps()       const { return m_showFps; }
int   ViewPortWindow::fpsCount()      const { return m_fpsCount; }
qreal ViewPortWindow::viewportX()     const { return m_viewportX; }
qreal ViewPortWindow::viewportY()     const { return m_viewportY; }
qreal ViewPortWindow::viewportScale() const { return m_viewportScale; }

void ViewPortWindow::setFpsCount(int value) {
    m_fpsCount = value;
    emit fpsCountChanged();
}

void ViewPortWindow::setViewportX(qreal x) {
    if (!qFuzzyCompare(m_viewportX, x)) { m_viewportX = x; emit viewportStateChanged(); }
}
void ViewPortWindow::setViewportY(qreal y) {
    if (!qFuzzyCompare(m_viewportY, y)) { m_viewportY = y; emit viewportStateChanged(); }
}
void ViewPortWindow::setViewportScale(qreal s) {
    if (!qFuzzyCompare(m_viewportScale, s)) { m_viewportScale = s; emit viewportStateChanged(); }
}

// ── FPS ───────────────────────────────────────────────────────────────────────

void ViewPortWindow::setShowFps(bool state) {
    m_showFps = state;
    emit showFpsChanged();

    disconnect(m_timerTriggerConn);
    disconnect(m_frameSwappedConn);

    if (state) {
        m_timerTriggerConn = connect(m_frameTimer, &QTimer::timeout, [&]() {
            setFpsCount(m_frameCount);
            m_frameCount = 0;
        });
        m_frameSwappedConn = connect(view(), &QQuickView::frameSwapped, [&]() {
            m_frameCount++;
        });
        m_frameTimer->start();
    } else {
        m_frameTimer->stop();
    }
}

void ViewPortWindow::setFullScreen(bool) {
    emit fullScreenToogle();
}

// ── Node management ───────────────────────────────────────────────────────────

void ViewPortWindow::connectBehaviour(Behaviours* object) {
    auto lambdaFun = [&, object](ConnectionModel* model) {
        Behaviours* output = model->output();
        Behaviours* input  = model->input();
        emit behaviourConnection(object, (output == object) ? input : output);
    };

    QMetaObject::Connection out = QObject::connect(object, &Behaviours::outputConnected, lambdaFun);
    QMetaObject::Connection in  = QObject::connect(object, &Behaviours::inputConnected,  lambdaFun);

    QObject::connect(object, &Behaviours::destroyed, [=]() {
        QObject::disconnect(out);
        QObject::disconnect(in);
    });
}

bool ViewPortWindow::addBehaviour(const QString& path, const QJsonObject infos) {
    const QString uuid = QUuid::createUuid().toString(QUuid::WithoutBraces);
    Behaviours* object = BehaviourLoader::instance()->loadBehaviour(path, infos);
    if (!object) return false;

    object->setBehaviourPath(path);
    object->setBehaviourInfos(infos);
    m_behaviours[uuid] = object;
    connectBehaviour(object);
    object->start();
    emit behaviourAdded(object);
    return true;
}

bool ViewPortWindow::addBehaviourWithUuid(const QString& path, const QJsonObject& infos,
                                           const QString& uuid,
                                           double x, double y, double w, double h,
                                           const QString& title)
{
    Behaviours* object = BehaviourLoader::instance()->loadBehaviour(path, infos);
    if (!object) return false;

    object->setBehaviourPath(path);
    object->setBehaviourInfos(infos);
    // Set geometry BEFORE emitting behaviourAdded so QML reads correct initial values
    object->setX(x);
    object->setY(y);
    if (w > 0) object->setWidth(w);
    if (h > 0) object->setHeight(h);
    if (!title.isEmpty()) object->setTitle(title);

    m_behaviours[uuid] = object;
    connectBehaviour(object);
    object->start();
    emit behaviourAdded(object);
    return true;
}

bool ViewPortWindow::removeBehaviourFromUUID(const QString& uuid) {
    return m_behaviours.remove(uuid);
}

bool ViewPortWindow::removeBehaviourObject(Behaviours* object) {
    const QString key = m_behaviours.key(object);
    delete object;
    return m_behaviours.remove(key);
}

void ViewPortWindow::clearBehaviours() {
    emit behavioursCleared();
    qDeleteAll(m_behaviours);
    m_behaviours.clear();
}

Behaviours* ViewPortWindow::searchBehaviourFromUUID(const QString& uuid) {
    return m_behaviours.value(uuid);
}

QString ViewPortWindow::getUUIDFromBehaviour(Behaviours* object) {
    return m_behaviours.key(object);
}

// ── Connections ───────────────────────────────────────────────────────────────

bool ViewPortWindow::addConnectionByUuids(const QString& outputUuid, const QString& outputMethod,
                                           const QString& inputUuid,  const QString& inputMethod)
{
    Behaviours* outputBeh = m_behaviours.value(outputUuid);
    Behaviours* inputBeh  = m_behaviours.value(inputUuid);
    if (!outputBeh || !inputBeh) return false;
    return outputBeh->addConnection(outputMethod, inputBeh, inputMethod);
}

// ── Workspace ─────────────────────────────────────────────────────────────────

void ViewPortWindow::restoreViewport(qreal x, qreal y, qreal scale) {
    m_viewportX     = x;
    m_viewportY     = y;
    m_viewportScale = scale;
    emit viewportRestoreRequested(x, y, scale);
}

QVariantList ViewPortWindow::getAllConnections() const {
    QVariantList result;
    for (auto it = m_behaviours.constBegin(); it != m_behaviours.constEnd(); ++it) {
        const QString& outputUuid = it.key();
        Behaviours* beh = it.value();
        const auto& outs = beh->outputConns();
        for (auto ci = outs.constBegin(); ci != outs.constEnd(); ++ci) {
            const QString& outputMethod = ci.key();
            Connections* conn = ci.value();
            for (ConnectionModel* model : conn->getAllConnections()) {
                const QString inputUuid = m_behaviours.key(model->input());
                if (inputUuid.isEmpty()) continue;
                QVariantMap entry;
                entry["outputUuid"]   = outputUuid;
                entry["outputMethod"] = outputMethod;
                entry["inputUuid"]    = inputUuid;
                entry["inputMethod"]  = QString::fromLatin1(model->slot().methodSignature());
                result.append(entry);
            }
        }
    }
    return result;
}

bool ViewPortWindow::saveWorkspace(const QString& name) {
    return WorkspaceManager::instance()->saveWorkspace(name);
}

bool ViewPortWindow::loadWorkspace(const QString& name) {
    return WorkspaceManager::instance()->loadWorkspace(name);
}
