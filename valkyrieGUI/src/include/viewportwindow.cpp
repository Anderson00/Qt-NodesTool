#include "viewportwindow.h"
#include "behaviours/behaviourregistry.h"
#include "behaviours/connections.h"
#include "behaviours/typecoercions.h"
#include "model/connectionmodel.h"
#include "utils/workspacemanager.h"
#include "utils/desktopmanager.h"
#include "commands/nodeundocommands.h"
#include "utils/toastmanager.h"
#include <QUuid>
#include <QVariantMap>
#include <QQmlContext>
#include <QPixmap>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QScreen>

ViewPortWindow::ViewPortWindow(QWidget* parent)
    : QMLWindow(parent, QUrl("qrc:/subwindows/ViewPortWindow.qml"))
{
    m_undoStack = new QUndoStack(this);
    connect(m_undoStack, &QUndoStack::canUndoChanged, this, &ViewPortWindow::undoStateChanged);
    connect(m_undoStack, &QUndoStack::canRedoChanged, this, &ViewPortWindow::undoStateChanged);
    connect(m_undoStack, &QUndoStack::cleanChanged,   this, &ViewPortWindow::undoStateChanged);
    connect(m_undoStack, &QUndoStack::indexChanged,   this, [this](int) { emit historyChanged(); });

    m_frameTimer = new QTimer(this);
    m_frameTimer->setTimerType(Qt::PreciseTimer);
    m_frameTimer->setInterval(1000);

    showWindow(QVector<QMLWindow::PropertyPair>({
        { "viewPort",        this }
    }));

    WorkspaceManager::instance()->setViewPort(this);
}

ViewPortWindow::~ViewPortWindow()
{
    // Destroy the QQuickView NOW, while ViewPortWindow is still fully alive.
    // If deferred to QMLWindow::~QMLWindow(), the vptr has already changed
    // and QML teardown callbacks (qt_metacall) hit the wrong vtable → ASSERT.
    destroyView();

    WorkspaceManager::instance()->setViewPort(nullptr);

    delete m_undoStack;
    m_undoStack = nullptr;

    qDeleteAll(m_behaviours);
    m_behaviours.clear();
}

// ── Properties ────────────────────────────────────────────────────────────────

QHash<QString, Behaviours*> ViewPortWindow::behaviours() { return m_behaviours; }
bool  ViewPortWindow::showFps()       const { return m_showFps; }
int   ViewPortWindow::fpsCount()      const { return m_fpsCount; }
qreal ViewPortWindow::viewportX()     const { return m_viewportX; }
qreal ViewPortWindow::viewportY()     const { return m_viewportY; }
qreal ViewPortWindow::viewportScale() const { return m_viewportScale; }
bool  ViewPortWindow::canUndo()       const { return m_undoStack->canUndo(); }
bool  ViewPortWindow::canRedo()       const { return m_undoStack->canRedo(); }
bool  ViewPortWindow::isClean()       const { return m_undoStack->isClean(); }
int   ViewPortWindow::historyCount()  const { return m_undoStack->count() + 1; }
int   ViewPortWindow::historyIndex()  const { return m_undoStack->index(); }

QString ViewPortWindow::historyText(int index) const {
    if (index <= 0 || index > m_undoStack->count()) return tr("Initial state");
    return m_undoStack->command(index - 1)->text();
}

void ViewPortWindow::jumpToHistory(int index) {
    m_undoStack->setIndex(index);
}

QUndoStack* ViewPortWindow::undoStack() const { return m_undoStack; }

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
    m_undoStack->push(new AddNodeCommand(this, NodeState{uuid, path, "", infos, 0, 0, 0, 0}));
    return true;
}

bool ViewPortWindow::addBehaviourWithUuid(const QString& path, const QJsonObject& infos,
                                           const QString& uuid,
                                           double x, double y, double w, double h,
                                           const QString& title,
                                           const QJsonObject& state)
{
    Behaviours* object = BehaviourRegistry::instance().create(infos["className"].toString());
    if (!object) return false;

    object->setBehaviourPath(path);
    object->setBehaviourInfos(infos);
    object->setUuid(uuid);
    // Set geometry BEFORE emitting behaviourAdded so QML reads correct initial values
    object->setX(x);
    object->setY(y);
    if (w > 0) object->setWidth(w);
    if (h > 0) object->setHeight(h);
    if (!title.isEmpty()) object->setTitle(title);

    m_behaviours[uuid] = object;
    connectBehaviour(object);
    object->start();

    // Restore internal state (from workspace load or undo/redo)
    if (!state.isEmpty())
        object->loadState(state);

    emit behaviourAdded(object);

    // Assign this node to the active virtual desktop. Loading a workspace
    // overrides this list via DesktopManager::deserialize() afterwards.
    DesktopManager::instance()->registerNewNode(uuid);
    return true;
}

bool ViewPortWindow::addPythonNodeWithScript(const QString& filePath, double x, double y) {
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return false;
    }
    QString content = QString::fromUtf8(f.readAll());
    
    QJsonObject state;
    state["script"] = content;
    
    QJsonObject infos;
    infos["name"] = QFileInfo(filePath).fileName();
    infos["type"] = Behaviours::CPP; // pythonbehaviour is registered as CPP type historically
    infos["className"] = "PythonBehaviour";
    infos["desc"] = "Loaded from " + QFileInfo(filePath).fileName();
    
    const QString uuid = QUuid::createUuid().toString(QUuid::WithoutBraces);
    
    return addBehaviourWithUuid("qrc:/behaviours/script/PythonScriptViewer.qml", infos, uuid, x, y, 360, 280, infos["name"].toString(), state);
}

bool ViewPortWindow::removeBehaviourFromUUID(const QString& uuid) {
    return m_behaviours.remove(uuid);
}

bool ViewPortWindow::removeBehaviourObject(Behaviours* object) {
    const QString key = object->uuid();
    DesktopManager::instance()->unregisterNode(key);
    m_behaviours.remove(key);
    emit behaviourRemoved(object, key);  // notify QML before delete
    delete object;
    return !key.isEmpty();
}

void ViewPortWindow::clearBehaviours() {
    emit behavioursCleared();
    qDeleteAll(m_behaviours);
    m_behaviours.clear();
    m_connectionComments.clear();
}

Behaviours* ViewPortWindow::searchBehaviourFromUUID(const QString& uuid) {
    return m_behaviours.value(uuid);
}

QString ViewPortWindow::getUUIDFromBehaviour(Behaviours* object) {
    return object ? object->uuid() : QString();
}

// ── Connections ───────────────────────────────────────────────────────────────

bool ViewPortWindow::addConnectionByUuids(const QString& outputUuid, const QString& outputMethod,
                                           const QString& inputUuid,  const QString& inputMethod)
{
    Behaviours* outputBeh = m_behaviours.value(outputUuid);
    Behaviours* inputBeh  = m_behaviours.value(inputUuid);
    if (!outputBeh || !inputBeh) return false;
    if (!outputBeh->addConnection(outputMethod, inputBeh, inputMethod)) return false;
    emit connectionAdded(outputUuid, outputMethod, inputUuid, inputMethod);
    return true;
}

bool ViewPortWindow::removeConnectionByUuids(const QString& outputUuid, const QString& outputMethod,
                                              const QString& inputUuid,  const QString& inputMethod)
{
    Behaviours* outputBeh = m_behaviours.value(outputUuid);
    Behaviours* inputBeh  = m_behaviours.value(inputUuid);
    if (!outputBeh || !inputBeh) return false;

    const auto& outs = outputBeh->outputConns();
    auto it = outs.find(outputMethod);
    if (it == outs.end()) return false;

    for (ConnectionModel* model : it.value()->getAllConnections()) {
        if (model->input() == inputBeh &&
            QString::fromLatin1(model->slot().methodSignature()) == inputMethod)
        {
            QObject::disconnect(model->connection());
            delete model;
            emit connectionRemoved(outputUuid, outputMethod, inputUuid, inputMethod);
            return true;
        }
    }
    return false;
}

// ── Undo/Redo ─────────────────────────────────────────────────────────────────

void ViewPortWindow::undo() { m_undoStack->undo(); }
void ViewPortWindow::redo() { m_undoStack->redo(); }

bool ViewPortWindow::removeNodeWithUndo(const QString& uuid) {
    Behaviours* beh = searchBehaviourFromUUID(uuid);
    if (!beh) return false;

    NodeState data{uuid, beh->behaviourPath(), beh->title(), beh->behaviourInfos(),
                   beh->x(), beh->y(), beh->width(), beh->height(),
                   beh->saveState()};

    QList<ConnState> conns;
    for (const QVariant& v : getAllConnections()) {
        const QVariantMap m = v.toMap();
        const QString out = m["outputUuid"].toString();
        const QString in  = m["inputUuid"].toString();
        if (out == uuid || in == uuid) {
            conns.append({out, m["outputMethod"].toString(),
                          in,  m["inputMethod"].toString()});
        }
    }

    m_undoStack->push(new RemoveNodeCommand(this, data, conns));
    return true;
}

bool ViewPortWindow::addConnectionWithUndo(const QString& outputUuid, const QString& outputMethod,
                                            const QString& inputUuid,  const QString& inputMethod)
{
    Behaviours* outputBeh = m_behaviours.value(outputUuid);
    Behaviours* inputBeh  = m_behaviours.value(inputUuid);
    if (!outputBeh || !inputBeh) return false;

    if (!outputBeh->isConnectionCompatible(outputMethod, inputBeh, inputMethod)) {
        ToastManager::instance()->show("Incompatible connection parameters", "error");
        return false;
    }

    m_undoStack->push(new AddConnectionCommand(this, ConnState{outputUuid, outputMethod, inputUuid, inputMethod}));
    return true;
}

bool ViewPortWindow::removeConnectionWithUndo(const QString& outputUuid, const QString& outputMethod,
                                               const QString& inputUuid,  const QString& inputMethod)
{
    m_undoStack->push(new RemoveConnectionCommand(this, ConnState{outputUuid, outputMethod, inputUuid, inputMethod}));
    return true;
}

void ViewPortWindow::recordNodeMove(const QString& uuid,
                                    double oldX, double oldY, double newX, double newY)
{
    if (qFuzzyCompare(oldX, newX) && qFuzzyCompare(oldY, newY)) return;
    m_undoStack->push(new MoveNodeCommand(this, uuid, oldX, oldY, newX, newY));
}

void ViewPortWindow::recordNodeResize(const QString& uuid,
                                      double oldX, double oldY, double oldW, double oldH,
                                      double newX, double newY, double newW, double newH)
{
    if (qFuzzyCompare(oldX, newX) && qFuzzyCompare(oldY, newY) &&
        qFuzzyCompare(oldW, newW) && qFuzzyCompare(oldH, newH)) return;
    m_undoStack->push(new ResizeNodeCommand(this, uuid,
                                            oldX, oldY, oldW, oldH,
                                            newX, newY, newW, newH));
}

void ViewPortWindow::beginUndoMacro(const QString& text) { m_undoStack->beginMacro(text); }
void ViewPortWindow::endUndoMacro()                      { m_undoStack->endMacro(); }

QVariantMap ViewPortWindow::getNodeData(const QString& uuid) const {
    auto* b = m_behaviours.value(uuid);
    if (!b) return {};
    QVariantMap map;
    map["path"]   = b->behaviourPath();
    map["title"]  = b->title();
    map["infos"]  = b->behaviourInfos().toVariantMap();
    map["x"]      = b->x();
    map["y"]      = b->y();
    map["width"]  = b->width();
    map["height"] = b->height();
    map["state"]  = b->saveState().toVariantMap();
    return map;
}

QString ViewPortWindow::pasteNode(const QVariantMap& data, double offsetX, double offsetY) {
    const QString newUuid = QUuid::createUuid().toString(QUuid::WithoutBraces);
    const QString path    = data.value("path").toString();
    const QString title   = data.value("title").toString();
    const QJsonObject infos = QJsonObject::fromVariantMap(data.value("infos").toMap());
    const QJsonObject state = QJsonObject::fromVariantMap(data.value("state").toMap());
    const double x = data.value("x").toDouble() + offsetX;
    const double y = data.value("y").toDouble() + offsetY;
    const double w = data.value("width").toDouble();
    const double h = data.value("height").toDouble();
    const bool ok = addBehaviourWithUuid(path, infos, newUuid, x, y, w, h, title, state);
    return ok ? newUuid : QString();
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
                const QString inputUuid = model->input()->uuid();
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

QVariantList ViewPortWindow::getNodeConnections(const QString& nodeUuid) const {
    QVariantList result;
    for (const QVariant& v : getAllConnections()) {
        QVariantMap m = v.toMap();
        if (m["outputUuid"].toString() == nodeUuid || m["inputUuid"].toString() == nodeUuid) {
            result.append(m);
        }
    }
    return result;
}

void ViewPortWindow::setConnectionComment(const QString& outputUuid, const QString& outputMethod,
                                          const QString& inputUuid,  const QString& inputMethod,
                                          const QString& comment) {
    const QString key = outputUuid + ":" + outputMethod + "->" + inputUuid + ":" + inputMethod;
    if (comment.isEmpty()) {
        m_connectionComments.remove(key);
    } else {
        m_connectionComments[key] = comment;
    }
}

QString ViewPortWindow::getConnectionComment(const QString& outputUuid, const QString& outputMethod,
                                             const QString& inputUuid,  const QString& inputMethod) const {
    const QString key = outputUuid + ":" + outputMethod + "->" + inputUuid + ":" + inputMethod;
    return m_connectionComments.value(key, QString());
}

bool ViewPortWindow::saveWorkspace(const QString& name) {
    bool ok = WorkspaceManager::instance()->saveWorkspace(name);
    if (ok) m_undoStack->setClean();
    return ok;
}

bool ViewPortWindow::loadWorkspace(const QString& name) {
    bool ok = WorkspaceManager::instance()->loadWorkspace(name);
    if (ok) m_undoStack->clear();
    return ok;
}

void ViewPortWindow::takeScreenshot(const QString& filePath) {
    QDir dir(QFileInfo(filePath).absolutePath());
    if (!dir.exists()) {
        dir.mkpath(".");
    }
    QImage image = view()->grabWindow();
    QPixmap screenshot = QPixmap::fromImage(image);
    screenshot.save(filePath);
}

bool ViewPortWindow::isPortCompatible(const QString& srcSig, const QString& dstSig) const
{
    const QByteArray src = srcSig.toUtf8();
    const QByteArray dst = dstSig.toUtf8();
    // Exact type match (Qt checks parameter types including base-class coercions)
    if (QMetaObject::checkConnectArgs(src.constData(), dst.constData()))
        return true;
    // Registered coercion relay pair
    const QByteArray srcP = TypeCoercions::extractParams(src);
    const QByteArray dstP = TypeCoercions::extractParams(dst);
    return TypeCoercions::isCoercible(srcP, dstP);
}
