#include "behaviourregistry.h"
#include <QDebug>

BehaviourRegistry& BehaviourRegistry::instance() {
    static BehaviourRegistry s_instance;
    return s_instance;
}

bool BehaviourRegistry::add(const BehaviourMeta& meta) {
    if (meta.className.isEmpty() || m_registry.contains(meta.className)) {
        qWarning() << "[BehaviourRegistry] Cannot register"
                   << meta.className << "(empty or duplicate)";
        return false;
    }
    m_registry.insert(meta.className, meta);
    qDebug() << "[BehaviourRegistry] Registered:" << meta.className
             << "(" << meta.category << ")";
    return true;
}

Behaviours* BehaviourRegistry::create(const QString& className) const {
    auto it = m_registry.constFind(className);
    if (it == m_registry.constEnd()) {
        qWarning() << "[BehaviourRegistry] Unknown class:" << className;
        return nullptr;
    }
    return it->factory();
}

bool BehaviourRegistry::contains(const QString& className) const {
    return m_registry.contains(className);
}

QList<BehaviourMeta> BehaviourRegistry::allMeta() const {
    return m_registry.values();
}

QList<BehaviourMeta> BehaviourRegistry::metaByCategory(const QString& category) const {
    QList<BehaviourMeta> result;
    for (const auto& meta : m_registry) {
        if (meta.category == category)
            result.append(meta);
    }
    return result;
}

QStringList BehaviourRegistry::categories() const {
    QSet<QString> cats;
    for (const auto& meta : m_registry)
        cats.insert(meta.category);
    return cats.values();
}

QJsonObject BehaviourRegistry::toDiscoveryJson() const {
    // Group by category, keyed as "Debug/{category}"
    // for backward-compat with the existing NodesDrawer / BehaviourLoader consumers
    QMap<QString, QJsonArray> grouped;
    for (const auto& meta : m_registry) {
        grouped[meta.category].append(meta.toJson());
    }

    QJsonObject result;
    for (auto it = grouped.constBegin(); it != grouped.constEnd(); ++it) {
        result["Debug/" + it.key()] = it.value();
    }
    return result;
}
