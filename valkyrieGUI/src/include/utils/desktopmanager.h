#ifndef DESKTOPMANAGER_H
#define DESKTOPMANAGER_H

#include <QObject>
#include <QHash>
#include <QSet>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonArray>
#include <QJsonObject>

class QQmlEngine;
class QJSEngine;

// Single desktop record. A desktop is a named "virtual workspace" inside the
// currently loaded project. It owns a list of node UUIDs (members), an optional
// per-desktop viewport state, and a display color. Pinned nodes are stored
// globally on the manager (cross-desktop), not per-desktop.
struct DesktopRecord {
    QString id;
    QString name;
    QString color;
    QStringList nodeUuids;          // membership (a node may appear in many)
    QVariantMap viewport;           // { x, y, scale } — optional snapshot
};

class DesktopManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList desktopList         READ desktopList         NOTIFY desktopListChanged)
    Q_PROPERTY(int          desktopCount        READ desktopCount        NOTIFY desktopListChanged)
    Q_PROPERTY(QString      currentDesktopId    READ currentDesktopId    NOTIFY currentDesktopChanged)
    Q_PROPERTY(int          currentDesktopIndex READ currentDesktopIndex NOTIFY currentDesktopChanged)
    Q_PROPERTY(QString      currentDesktopName  READ currentDesktopName  NOTIFY currentDesktopChanged)
    Q_PROPERTY(QString      currentDesktopColor READ currentDesktopColor NOTIFY currentDesktopChanged)
    Q_PROPERTY(int          softLimit           READ softLimit           CONSTANT)
    Q_PROPERTY(QStringList  pinnedNodes         READ pinnedNodes         NOTIFY pinnedNodesChanged)

public:
    static constexpr int SOFT_LIMIT = 8;

    static DesktopManager* instance();
    static QObject* qmlSingletonProvider(QQmlEngine*, QJSEngine*);

    // ── Read accessors ────────────────────────────────────────────────────────
    QVariantList desktopList() const;
    int          desktopCount() const;
    QString      currentDesktopId() const;
    int          currentDesktopIndex() const;
    QString      currentDesktopName() const;
    QString      currentDesktopColor() const;
    int          softLimit() const { return SOFT_LIMIT; }
    QStringList  pinnedNodes() const { return m_pinned.values(); }

    // ── Serialization (called by WorkspaceManager) ────────────────────────────
    QJsonArray  serialize() const;                         // desktops
    QJsonArray  serializePinned() const;                   // pinned node UUIDs
    QString     serializeCurrentDesktopId() const { return m_currentId; }
    void        deserialize(const QJsonArray& desktopsJson,
                            const QJsonArray& pinnedJson,
                            const QString& currentId);
    void        clearAll();   // reset to a single empty default desktop

public slots:
    // ── Desktop CRUD ──────────────────────────────────────────────────────────
    // addDesktop emits desktopLimitWarning() and returns "" when the soft limit
    // is reached and the warning has not yet been dismissed in this session.
    Q_INVOKABLE QString addDesktop(const QString& name = QString());
    Q_INVOKABLE QString addDesktopForced(const QString& name = QString());
    Q_INVOKABLE bool    removeDesktop(const QString& id);
    Q_INVOKABLE bool    renameDesktop(const QString& id, const QString& newName);
    Q_INVOKABLE bool    setDesktopColor(const QString& id, const QString& color);
    Q_INVOKABLE bool    duplicateDesktop(const QString& id);
    Q_INVOKABLE bool    reorderDesktops(int fromIndex, int toIndex);

    // ── Navigation ────────────────────────────────────────────────────────────
    Q_INVOKABLE bool switchToDesktop(const QString& id);
    Q_INVOKABLE bool switchToDesktopByIndex(int index);
    Q_INVOKABLE bool nextDesktop();
    Q_INVOKABLE bool previousDesktop();

    // ── Node ↔ desktop membership ─────────────────────────────────────────────
    Q_INVOKABLE bool        addNodeToDesktop(const QString& desktopId, const QString& nodeUuid);
    Q_INVOKABLE bool        removeNodeFromDesktop(const QString& desktopId, const QString& nodeUuid);
    Q_INVOKABLE bool        moveNodeToDesktop(const QString& nodeUuid,
                                              const QString& fromDesktopId,
                                              const QString& toDesktopId);
    Q_INVOKABLE bool        isNodeInDesktop(const QString& nodeUuid, const QString& desktopId) const;
    Q_INVOKABLE QStringList getNodeDesktops(const QString& nodeUuid) const;
    Q_INVOKABLE bool        shareNodeAcrossDesktops(const QString& nodeUuid, const QStringList& desktopIds);

    // ── Pinned (global) nodes ─────────────────────────────────────────────────
    Q_INVOKABLE bool pinNode(const QString& nodeUuid);
    Q_INVOKABLE bool unpinNode(const QString& nodeUuid);
    Q_INVOKABLE bool isPinned(const QString& nodeUuid) const;
    Q_INVOKABLE bool toggleNodePinned(const QString& nodeUuid);

    // ── Visibility query (used by QML to set node .visible) ───────────────────
    // A node is visible on the current desktop when it's pinned OR it's a
    // member of the current desktop. When no desktops exist, everything is
    // visible (graceful fallback for legacy workspaces).
    Q_INVOKABLE bool isNodeVisibleOnCurrentDesktop(const QString& nodeUuid) const;

    // ── Per-desktop viewport (camera) ─────────────────────────────────────────
    // Each desktop remembers its last canvas pan/zoom so switching back
    // restores the user's view. setDesktopViewport is invoked by QML right
    // before switching away from a desktop (via the aboutToLeaveDesktop signal).
    // getDesktopViewport returns an empty map for desktops that have never
    // been visited — QML interprets this as "use the current view as-is".
    Q_INVOKABLE void        setDesktopViewport(const QString& id, double x, double y, double scale);
    Q_INVOKABLE QVariantMap getDesktopViewport(const QString& id) const;

    // ── Add helper ────────────────────────────────────────────────────────────
    // Called by ViewPortWindow whenever a new node is created. The new node is
    // assigned to the currently active desktop (or no desktop when none exist).
    Q_INVOKABLE void registerNewNode(const QString& nodeUuid);
    Q_INVOKABLE void unregisterNode(const QString& nodeUuid);

    // ── Warning dismissal ─────────────────────────────────────────────────────
    Q_INVOKABLE void dismissDesktopWarning() { m_warningDismissed = true; }

signals:
    void desktopListChanged();
    void currentDesktopChanged();
    // Fires BEFORE m_currentId actually changes, giving QML a chance to
    // snapshot the outgoing desktop's viewport into the manager.
    void aboutToLeaveDesktop(QString id);
    void desktopLimitWarning(QString pendingName);
    void nodeVisibilityChanged(QString nodeUuid, bool visible);
    void nodeDesktopMembershipChanged(QString nodeUuid);
    void pinnedNodesChanged();

private:
    explicit DesktopManager(QObject* parent = nullptr);

    QString newUuid() const;
    QString defaultDesktopName() const;
    DesktopRecord* findById(const QString& id);
    const DesktopRecord* findById(const QString& id) const;
    int indexOfId(const QString& id) const;

    // Storage
    QList<DesktopRecord> m_desktops;
    QString              m_currentId;
    QSet<QString>        m_pinned;

    // Session-only flag: once dismissed via the QML popup, do not show again
    // until the application restarts.
    bool m_warningDismissed = false;
};

#endif // DESKTOPMANAGER_H
