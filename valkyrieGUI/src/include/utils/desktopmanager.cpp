#include "desktopmanager.h"

#include <QUuid>
#include <QtQml/QQmlEngine>
#include <QJsonObject>
#include <QJsonValue>

DesktopManager::DesktopManager(QObject* parent) : QObject(parent)
{
    // Start with a single default desktop so the UI is never in a "no desktops"
    // state for new projects.
    DesktopRecord d;
    d.id    = newUuid();
    d.name  = "Desktop 1";
    d.color = "#4CAF50";
    m_desktops.append(d);
    m_currentId = d.id;
}

DesktopManager* DesktopManager::instance()
{
    // Meyers singleton: constructed once, destroyed on app exit in correct order
    static DesktopManager s_instance;
    return &s_instance;
}

QObject* DesktopManager::qmlSingletonProvider(QQmlEngine*, QJSEngine*)
{
    return DesktopManager::instance();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

QString DesktopManager::newUuid() const
{
    return QUuid::createUuid().toString(QUuid::WithoutBraces);
}

QString DesktopManager::defaultDesktopName() const
{
    return QStringLiteral("Desktop %1").arg(m_desktops.size() + 1);
}

DesktopRecord* DesktopManager::findById(const QString& id)
{
    for (auto& d : m_desktops) if (d.id == id) return &d;
    return nullptr;
}

const DesktopRecord* DesktopManager::findById(const QString& id) const
{
    for (const auto& d : m_desktops) if (d.id == id) return &d;
    return nullptr;
}

int DesktopManager::indexOfId(const QString& id) const
{
    for (int i = 0; i < m_desktops.size(); ++i)
        if (m_desktops[i].id == id) return i;
    return -1;
}

// ── Read accessors ────────────────────────────────────────────────────────────

QVariantList DesktopManager::desktopList() const
{
    QVariantList out;
    out.reserve(m_desktops.size());
    for (const auto& d : m_desktops) {
        QVariantMap m;
        m["id"]        = d.id;
        m["name"]      = d.name;
        m["color"]     = d.color;
        m["nodeCount"] = d.nodeUuids.size();
        out.append(m);
    }
    return out;
}

int     DesktopManager::desktopCount()        const { return m_desktops.size(); }
QString DesktopManager::currentDesktopId()    const { return m_currentId; }

int DesktopManager::currentDesktopIndex() const
{
    return indexOfId(m_currentId);
}

QString DesktopManager::currentDesktopName() const
{
    const DesktopRecord* d = findById(m_currentId);
    return d ? d->name : QString();
}

QString DesktopManager::currentDesktopColor() const
{
    const DesktopRecord* d = findById(m_currentId);
    return d ? d->color : QString();
}

// ── CRUD ──────────────────────────────────────────────────────────────────────

QString DesktopManager::addDesktop(const QString& name)
{
    if (m_desktops.size() >= SOFT_LIMIT && !m_warningDismissed) {
        emit desktopLimitWarning(name.isEmpty() ? defaultDesktopName() : name);
        return QString();
    }
    return addDesktopForced(name);
}

QString DesktopManager::addDesktopForced(const QString& name)
{
    static const QStringList kColors = {
        "#4CAF50", "#2196F3", "#FF9800", "#9C27B0",
        "#F44336", "#00BCD4", "#FF5722", "#607D8B",
        "#795548", "#3F51B5"
    };

    DesktopRecord d;
    d.id    = newUuid();
    d.name  = name.isEmpty() ? defaultDesktopName() : name;
    d.color = kColors[m_desktops.size() % kColors.size()];
    m_desktops.append(d);
    emit desktopListChanged();
    return d.id;
}

bool DesktopManager::removeDesktop(const QString& id)
{
    if (m_desktops.size() <= 1) return false;  // always keep at least one
    int idx = indexOfId(id);
    if (idx < 0) return false;

    const bool wasCurrent = (m_currentId == id);

    // Give QML a chance to snapshot the outgoing desktop's viewport before
    // removal — same contract as switchToDesktop()
    if (wasCurrent && !m_currentId.isEmpty())
        emit aboutToLeaveDesktop(m_currentId);

    m_desktops.removeAt(idx);

    if (wasCurrent) {
        int newIdx = qBound(0, idx, m_desktops.size() - 1);
        m_currentId = m_desktops[newIdx].id;
        emit currentDesktopChanged();
    }
    emit desktopListChanged();
    return true;
}

bool DesktopManager::renameDesktop(const QString& id, const QString& newName)
{
    DesktopRecord* d = findById(id);
    if (!d || newName.trimmed().isEmpty()) return false;
    d->name = newName.trimmed();
    if (id == m_currentId) emit currentDesktopChanged();
    emit desktopListChanged();
    return true;
}

bool DesktopManager::setDesktopColor(const QString& id, const QString& color)
{
    DesktopRecord* d = findById(id);
    if (!d || color.isEmpty()) return false;
    d->color = color;
    if (id == m_currentId) emit currentDesktopChanged();
    emit desktopListChanged();
    return true;
}

bool DesktopManager::duplicateDesktop(const QString& id)
{
    const DesktopRecord* src = findById(id);
    if (!src) return false;
    if (m_desktops.size() >= SOFT_LIMIT && !m_warningDismissed) {
        emit desktopLimitWarning(src->name + " (copy)");
        return false;
    }
    DesktopRecord copy;
    copy.id        = newUuid();
    copy.name      = src->name + " (copy)";
    copy.color     = src->color;
    copy.nodeUuids = src->nodeUuids;   // share same members visually; deep clone is a UX choice we skip here
    copy.viewport  = src->viewport;
    m_desktops.append(copy);
    emit desktopListChanged();
    return true;
}

bool DesktopManager::reorderDesktops(int fromIndex, int toIndex)
{
    if (fromIndex < 0 || fromIndex >= m_desktops.size()) return false;
    if (toIndex   < 0 || toIndex   >= m_desktops.size()) return false;
    if (fromIndex == toIndex) return true;
    m_desktops.move(fromIndex, toIndex);
    emit desktopListChanged();
    return true;
}

// ── Navigation ────────────────────────────────────────────────────────────────

bool DesktopManager::switchToDesktop(const QString& id)
{
    if (id == m_currentId) return true;
    if (indexOfId(id) < 0) return false;
    // Give QML a chance to snapshot the outgoing viewport before the switch
    if (!m_currentId.isEmpty())
        emit aboutToLeaveDesktop(m_currentId);
    m_currentId = id;
    emit currentDesktopChanged();
    return true;
}

bool DesktopManager::switchToDesktopByIndex(int index)
{
    if (index < 0 || index >= m_desktops.size()) return false;
    return switchToDesktop(m_desktops[index].id);
}

bool DesktopManager::nextDesktop()
{
    if (m_desktops.size() <= 1) return false;
    int idx = currentDesktopIndex();
    if (idx < 0) return false;
    return switchToDesktopByIndex((idx + 1) % m_desktops.size());
}

bool DesktopManager::previousDesktop()
{
    if (m_desktops.size() <= 1) return false;
    int idx = currentDesktopIndex();
    if (idx < 0) return false;
    return switchToDesktopByIndex((idx - 1 + m_desktops.size()) % m_desktops.size());
}

// ── Node ↔ desktop membership ────────────────────────────────────────────────

bool DesktopManager::addNodeToDesktop(const QString& desktopId, const QString& nodeUuid)
{
    DesktopRecord* d = findById(desktopId);
    if (!d || nodeUuid.isEmpty()) return false;
    if (d->nodeUuids.contains(nodeUuid)) return true;
    d->nodeUuids.append(nodeUuid);
    emit nodeDesktopMembershipChanged(nodeUuid);
    emit desktopListChanged();
    return true;
}

bool DesktopManager::removeNodeFromDesktop(const QString& desktopId, const QString& nodeUuid)
{
    DesktopRecord* d = findById(desktopId);
    if (!d) return false;
    if (!d->nodeUuids.removeAll(nodeUuid)) return false;
    emit nodeDesktopMembershipChanged(nodeUuid);
    emit desktopListChanged();
    return true;
}

bool DesktopManager::moveNodeToDesktop(const QString& nodeUuid,
                                       const QString& fromDesktopId,
                                       const QString& toDesktopId)
{
    DesktopRecord* from = findById(fromDesktopId);
    DesktopRecord* to   = findById(toDesktopId);
    if (!to) return false;
    if (from) from->nodeUuids.removeAll(nodeUuid);
    if (!to->nodeUuids.contains(nodeUuid)) to->nodeUuids.append(nodeUuid);
    emit nodeDesktopMembershipChanged(nodeUuid);
    emit desktopListChanged();
    return true;
}

bool DesktopManager::isNodeInDesktop(const QString& nodeUuid, const QString& desktopId) const
{
    const DesktopRecord* d = findById(desktopId);
    return d && d->nodeUuids.contains(nodeUuid);
}

QStringList DesktopManager::getNodeDesktops(const QString& nodeUuid) const
{
    QStringList ids;
    for (const auto& d : m_desktops)
        if (d.nodeUuids.contains(nodeUuid)) ids.append(d.id);
    return ids;
}

bool DesktopManager::shareNodeAcrossDesktops(const QString& nodeUuid, const QStringList& desktopIds)
{
    if (nodeUuid.isEmpty()) return false;
    bool changed = false;
    for (auto& d : m_desktops) {
        const bool shouldHave = desktopIds.contains(d.id);
        const bool hasIt      = d.nodeUuids.contains(nodeUuid);
        if (shouldHave && !hasIt)      { d.nodeUuids.append(nodeUuid); changed = true; }
        else if (!shouldHave && hasIt) { d.nodeUuids.removeAll(nodeUuid); changed = true; }
    }
    if (changed) {
        emit nodeDesktopMembershipChanged(nodeUuid);
        emit desktopListChanged();
    }
    return changed;
}

// ── Pinned nodes ──────────────────────────────────────────────────────────────

bool DesktopManager::pinNode(const QString& nodeUuid)
{
    if (nodeUuid.isEmpty() || m_pinned.contains(nodeUuid)) return false;
    m_pinned.insert(nodeUuid);
    emit pinnedNodesChanged();
    emit nodeVisibilityChanged(nodeUuid, true);
    return true;
}

bool DesktopManager::unpinNode(const QString& nodeUuid)
{
    if (!m_pinned.remove(nodeUuid)) return false;
    emit pinnedNodesChanged();
    // Visibility may change if the node isn't in the current desktop
    emit nodeVisibilityChanged(nodeUuid, isNodeVisibleOnCurrentDesktop(nodeUuid));
    return true;
}

bool DesktopManager::isPinned(const QString& nodeUuid) const
{
    return m_pinned.contains(nodeUuid);
}

bool DesktopManager::toggleNodePinned(const QString& nodeUuid)
{
    return isPinned(nodeUuid) ? unpinNode(nodeUuid) : pinNode(nodeUuid);
}

// ── Visibility / lifecycle ────────────────────────────────────────────────────

bool DesktopManager::isNodeVisibleOnCurrentDesktop(const QString& nodeUuid) const
{
    if (m_desktops.isEmpty()) return true;
    if (m_pinned.contains(nodeUuid)) return true;
    const DesktopRecord* d = findById(m_currentId);
    return d && d->nodeUuids.contains(nodeUuid);
}

void DesktopManager::setDesktopViewport(const QString& id, double x, double y, double scale)
{
    DesktopRecord* d = findById(id);
    if (!d) return;
    d->viewport.insert("x",     x);
    d->viewport.insert("y",     y);
    d->viewport.insert("scale", scale);
    // No signal: this is internal state QML pushes in; emitting would loop
    // back into the QML restore path and fight the user's pan/zoom.
}

QVariantMap DesktopManager::getDesktopViewport(const QString& id) const
{
    const DesktopRecord* d = findById(id);
    if (!d) return {};
    return d->viewport;
}

void DesktopManager::registerNewNode(const QString& nodeUuid)
{
    if (nodeUuid.isEmpty()) return;
    DesktopRecord* d = findById(m_currentId);
    if (!d) return;
    if (!d->nodeUuids.contains(nodeUuid)) {
        d->nodeUuids.append(nodeUuid);
        emit nodeDesktopMembershipChanged(nodeUuid);
        emit desktopListChanged();
    }
}

void DesktopManager::unregisterNode(const QString& nodeUuid)
{
    bool changed = false;
    for (auto& d : m_desktops) {
        if (d.nodeUuids.removeAll(nodeUuid) > 0) changed = true;
    }
    if (m_pinned.remove(nodeUuid)) {
        emit pinnedNodesChanged();
        changed = true;
    }
    if (changed) {
        emit nodeDesktopMembershipChanged(nodeUuid);
        emit desktopListChanged();
    }
}

// ── Serialization ─────────────────────────────────────────────────────────────

QJsonArray DesktopManager::serialize() const
{
    QJsonArray arr;
    for (const auto& d : m_desktops) {
        QJsonObject o;
        o["id"]        = d.id;
        o["name"]      = d.name;
        o["color"]     = d.color;
        QJsonArray uuids;
        for (const auto& u : d.nodeUuids) uuids.append(u);
        o["nodeUuids"] = uuids;
        if (!d.viewport.isEmpty()) {
            QJsonObject vp;
            vp["x"]     = d.viewport.value("x", 0).toDouble();
            vp["y"]     = d.viewport.value("y", 0).toDouble();
            vp["scale"] = d.viewport.value("scale", 1.0).toDouble();
            o["viewport"] = vp;
        }
        arr.append(o);
    }
    return arr;
}

QJsonArray DesktopManager::serializePinned() const
{
    // Sort before serializing to produce deterministic JSON (avoids noisy git diffs)
    QList<QString> sorted = m_pinned.values();
    std::sort(sorted.begin(), sorted.end());

    QJsonArray arr;
    for (const auto& u : sorted) arr.append(u);
    return arr;
}

void DesktopManager::deserialize(const QJsonArray& desktopsJson,
                                 const QJsonArray& pinnedJson,
                                 const QString& currentId)
{
    m_desktops.clear();
    m_pinned.clear();

    for (const QJsonValue& v : desktopsJson) {
        const QJsonObject o = v.toObject();
        DesktopRecord d;
        d.id    = o.value("id").toString();
        d.name  = o.value("name").toString("Desktop");
        d.color = o.value("color").toString("#4CAF50");
        const QJsonArray uuids = o.value("nodeUuids").toArray();
        for (const QJsonValue& uv : uuids) d.nodeUuids.append(uv.toString());
        if (o.contains("viewport")) {
            const QJsonObject vp = o.value("viewport").toObject();
            d.viewport.insert("x",     vp.value("x").toDouble(0));
            d.viewport.insert("y",     vp.value("y").toDouble(0));
            d.viewport.insert("scale", vp.value("scale").toDouble(1.0));
        }
        if (d.id.isEmpty()) d.id = newUuid();
        m_desktops.append(d);
    }

    // Always guarantee at least one desktop exists
    if (m_desktops.isEmpty()) {
        DesktopRecord d;
        d.id    = newUuid();
        d.name  = "Desktop 1";
        d.color = "#4CAF50";
        m_desktops.append(d);
    }

    for (const QJsonValue& v : pinnedJson) m_pinned.insert(v.toString());

    if (!currentId.isEmpty() && indexOfId(currentId) >= 0)
        m_currentId = currentId;
    else
        m_currentId = m_desktops.first().id;

    emit desktopListChanged();
    emit currentDesktopChanged();
    emit pinnedNodesChanged();
}

void DesktopManager::clearAll()
{
    m_desktops.clear();
    m_pinned.clear();
    DesktopRecord d;
    d.id    = newUuid();
    d.name  = "Desktop 1";
    d.color = "#4CAF50";
    m_desktops.append(d);
    m_currentId = d.id;
    emit desktopListChanged();
    emit currentDesktopChanged();
    emit pinnedNodesChanged();
}
