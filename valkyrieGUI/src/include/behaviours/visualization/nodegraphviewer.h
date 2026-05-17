#ifndef NODEGRAPHVIEWER_H
#define NODEGRAPHVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariantMap>
#include <QVariantList>
#include <QStringList>
#include <QRandomGenerator>
#include <behaviours/behaviours.h>

class NodeGraphViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int     nodeCount  READ nodeCount  NOTIFY nodeCountChanged)
    Q_PROPERTY(int     edgeCount  READ edgeCount  NOTIFY edgeCountChanged)
    Q_PROPERTY(QString layout     READ layout     WRITE setLayout NOTIFY layoutChanged)

public:
    explicit NodeGraphViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int     nodeCount() const { return m_nodes.size(); }
    int     edgeCount() const { return m_edges.size(); }
    QString layout()    const { return m_layout; }
    void    setLayout(const QString& type);

    Q_INVOKABLE QVariantMap  getNodes() const;
    Q_INVOKABLE QVariantList getEdges() const;
    Q_INVOKABLE void         setNodePos(QString id, double x, double y);
    Q_INVOKABLE void         setPinned(QString id, bool pinned);
    Q_INVOKABLE void         applyLayout();

public slots:
    void addNode(QString id, QString label);
    void addEdge(QString fromId, QString toId, QString label);
    void removeNode(QString id);
    void clear();
    void setLayoutSlot(QString type);

signals:
    // Node outputs
    void nodeClicked(QString id, QString label);
    void edgeClicked(QString fromId, QString toId);

    // Internal QML bridge
    void internalGraphChanged();
    void internalClear();

    // Property notifiers
    void nodeCountChanged();
    void edgeCountChanged();
    void layoutChanged();

private:
    void applyCircularLayout();
    void applyTreeLayout();

    // m_nodes: id -> {label, x, y, pinned}
    QMap<QString, QVariantMap>  m_nodesMap;
    // m_edges: each entry is {from, to, label}
    QList<QVariantMap>          m_edgeList;
    QString                     m_layout = "force";
};

#endif // NODEGRAPHVIEWER_H
