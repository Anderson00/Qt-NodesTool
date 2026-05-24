#include "nodegraphviewer.h"
#include "behaviours/behaviourregistry.h"

#include <QJsonArray>
#include <QtMath>

REGISTER_BEHAVIOUR(NodeGraphViewer, "Node Graph Viewer", "Visualize graph topology with force-directed layout", "visualization", 5, 2)

NodeGraphViewer::NodeGraphViewer(QObject *parent)
    : Behaviours(parent)
{
    setWidth(400);
    setHeight(380);
    setContentHeight(380);
    setQmlBodyUrl("qrc:/behaviours/visualization/NodeGraphViewer.qml");

    addInputOutputExclusion(QList<QString>({
        "internalGraphChanged()",
        "internalClear()"
    }));
}

QMap<QString, QVariant> NodeGraphViewer::loadInfos()
{
    return NodeGraphViewer::static_infos();
}

QMap<QString, QVariant> NodeGraphViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "NodeGraphViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "NodeGraphViewer"},
        {"desc",          "Visualize graph topology with force-directed layout"},
        {"inputs_count",  "5"},
        {"outputs_count", "2"}
    });
}

void NodeGraphViewer::setLayout(const QString& type)
{
    if (m_layout != type) {
        m_layout = type;
        emit layoutChanged();
    }
}

QVariantMap NodeGraphViewer::getNodes() const
{
    QVariantMap result;
    for (auto it = m_nodesMap.begin(); it != m_nodesMap.end(); ++it) {
        result.insert(it.key(), it.value());
    }
    return result;
}

QVariantList NodeGraphViewer::getEdges() const
{
    QVariantList result;
    for (const QVariantMap& e : m_edgeList) {
        result.append(e);
    }
    return result;
}

void NodeGraphViewer::setNodePos(QString id, double x, double y)
{
    if (!m_nodesMap.contains(id))
        return;
    QVariantMap node = m_nodesMap[id];
    node["x"] = x;
    node["y"] = y;
    m_nodesMap[id] = node;
}

void NodeGraphViewer::setPinned(QString id, bool pinned)
{
    if (!m_nodesMap.contains(id))
        return;
    QVariantMap node = m_nodesMap[id];
    node["pinned"] = pinned;
    m_nodesMap[id] = node;
    emit internalGraphChanged();
}

void NodeGraphViewer::applyLayout()
{
    if (m_layout == "circular")
        applyCircularLayout();
    else if (m_layout == "tree")
        applyTreeLayout();
    // "force" is handled by QML timer
    emit internalGraphChanged();
}

void NodeGraphViewer::addNode(QString id, QString label)
{
    if (m_nodesMap.contains(id))
        return;
    QVariantMap node;
    node["label"]  = label;
    node["x"]      = static_cast<double>(QRandomGenerator::global()->bounded(60, 340));
    node["y"]      = static_cast<double>(QRandomGenerator::global()->bounded(40, 300));
    node["pinned"] = false;
    m_nodesMap.insert(id, node);
    emit nodeCountChanged();
    emit internalGraphChanged();
}

void NodeGraphViewer::addEdge(QString fromId, QString toId, QString label)
{
    QVariantMap edge;
    edge["from"]  = fromId;
    edge["to"]    = toId;
    edge["label"] = label;
    m_edgeList.append(edge);
    emit edgeCountChanged();
    emit internalGraphChanged();
}

void NodeGraphViewer::removeNode(QString id)
{
    if (!m_nodesMap.contains(id))
        return;
    m_nodesMap.remove(id);

    // Remove edges referencing this node
    QList<QVariantMap> remaining;
    for (const QVariantMap& e : m_edgeList) {
        if (e["from"].toString() != id && e["to"].toString() != id)
            remaining.append(e);
    }
    m_edgeList = remaining;

    emit nodeCountChanged();
    emit edgeCountChanged();
    emit internalGraphChanged();
}

void NodeGraphViewer::clear()
{
    m_nodesMap.clear();
    m_edgeList.clear();
    emit nodeCountChanged();
    emit edgeCountChanged();
    emit internalClear();
}

void NodeGraphViewer::setLayoutSlot(QString type)
{
    setLayout(type);
    applyLayout();
}

void NodeGraphViewer::applyCircularLayout()
{
    if (m_nodesMap.isEmpty())
        return;
    int n = m_nodesMap.size();
    double cx = 200.0, cy = 160.0, r = 120.0;
    int i = 0;
    for (auto it = m_nodesMap.begin(); it != m_nodesMap.end(); ++it, ++i) {
        double angle = (2.0 * M_PI * i) / n;
        QVariantMap node = it.value();
        node["x"] = cx + r * qCos(angle);
        node["y"] = cy + r * qSin(angle);
        it.value() = node;
    }
}

void NodeGraphViewer::applyTreeLayout()
{
    if (m_nodesMap.isEmpty())
        return;

    // BFS from first node key
    QString root = m_nodesMap.begin().key();
    QMap<QString, QList<QString>> adj;
    for (const QVariantMap& e : m_edgeList) {
        adj[e["from"].toString()].append(e["to"].toString());
    }

    QList<QString> queue;
    QMap<QString, int> level;
    QMap<int, int> levelCount;
    queue.append(root);
    level[root] = 0;

    int head = 0;
    while (head < queue.size()) {
        QString cur = queue[head++];
        int lv = level[cur];
        levelCount[lv]++;
        for (const QString& nb : adj[cur]) {
            if (!level.contains(nb)) {
                level[nb] = lv + 1;
                queue.append(nb);
            }
        }
    }

    // Position by level
    QMap<int, int> levelIdx;
    double xSpacing = 80.0, ySpacing = 70.0;
    for (const QString& id : queue) {
        if (!m_nodesMap.contains(id)) continue;
        int lv  = level[id];
        int idx = levelIdx[lv]++;
        int cnt = levelCount[lv];
        double startX = 200.0 - (cnt - 1) * xSpacing / 2.0;
        QVariantMap node = m_nodesMap[id];
        node["x"] = startX + idx * xSpacing;
        node["y"] = 30.0 + lv * ySpacing;
        m_nodesMap[id] = node;
    }
}

QJsonObject NodeGraphViewer::saveState() const
{
    QJsonObject state;
    state["layout"] = m_layout;

    QJsonObject nodesObj;
    for (auto it = m_nodesMap.begin(); it != m_nodesMap.end(); ++it) {
        QJsonObject n;
        n["label"]  = it.value()["label"].toString();
        n["x"]      = it.value()["x"].toDouble();
        n["y"]      = it.value()["y"].toDouble();
        n["pinned"] = it.value()["pinned"].toBool();
        nodesObj[it.key()] = n;
    }
    state["nodes"] = nodesObj;

    QJsonArray edgesArr;
    for (const QVariantMap& e : m_edgeList) {
        QJsonObject ej;
        ej["from"]  = e["from"].toString();
        ej["to"]    = e["to"].toString();
        ej["label"] = e["label"].toString();
        edgesArr.append(ej);
    }
    state["edges"] = edgesArr;
    return state;
}

void NodeGraphViewer::loadState(const QJsonObject& state)
{
    m_nodesMap.clear();
    m_edgeList.clear();

    if (state.contains("layout"))
        setLayout(state["layout"].toString("force"));

    if (state.contains("nodes")) {
        QJsonObject nodesObj = state["nodes"].toObject();
        for (auto it = nodesObj.begin(); it != nodesObj.end(); ++it) {
            QJsonObject n = it.value().toObject();
            QVariantMap node;
            node["label"]  = n["label"].toString();
            node["x"]      = n["x"].toDouble();
            node["y"]      = n["y"].toDouble();
            node["pinned"] = n["pinned"].toBool();
            m_nodesMap.insert(it.key(), node);
        }
    }

    if (state.contains("edges")) {
        for (const auto& ev : state["edges"].toArray()) {
            QJsonObject ej = ev.toObject();
            QVariantMap edge;
            edge["from"]  = ej["from"].toString();
            edge["to"]    = ej["to"].toString();
            edge["label"] = ej["label"].toString();
            m_edgeList.append(edge);
        }
    }

    emit nodeCountChanged();
    emit edgeCountChanged();
    emit internalGraphChanged();
}
