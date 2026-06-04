#include "behaviourregistry.h"
#include <QCoreApplication>
#include <QDebug>
#include <QDir>

BehaviourRegistry::BehaviourRegistry() : QObject(nullptr) {
    // Create plugin directories relative to the executable, not to CWD
    const QString base = QCoreApplication::applicationDirPath() + "/Behaviours";
    QDir().mkpath(base);
    QDir(base).mkdir("Debug");
    QDir(base).mkdir("Plugins");
}

BehaviourRegistry& BehaviourRegistry::instance() {
    static BehaviourRegistry s_instance;
    return s_instance;
}

QObject* BehaviourRegistry::qmlSingletonProvider(QQmlEngine*, QJSEngine*) {
    // QML singletons must NOT be garbage-collected by the engine
    QQmlEngine::setObjectOwnership(&instance(), QQmlEngine::CppOwnership);
    return &instance();
}

bool BehaviourRegistry::add(const BehaviourMeta& meta) {
    if (meta.className.isEmpty() || m_registry.contains(meta.className)) {
        qWarning() << "[BehaviourRegistry] Cannot register"
                   << meta.className << "(empty or duplicate)";
        return false;
    }
    m_registry.insert(meta.className, meta);
    m_dirty = true;
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

// ── QML-facing slots ─────────────────────────────────────────────────────────

QJsonObject BehaviourRegistry::discoverAll() {
    if (m_dirty) {
        // Group by category, keyed as "Debug/{category}" for NodesDrawer
        QMap<QString, QJsonArray> grouped;
        for (const auto& meta : m_registry)
            grouped[meta.category].append(meta.toJson());

        m_cachedDiscovery = QJsonObject();
        for (auto it = grouped.constBegin(); it != grouped.constEnd(); ++it)
            m_cachedDiscovery["Debug/" + it.key()] = it.value();

        m_dirty = false;
    }
    return m_cachedDiscovery;
}

QJsonArray BehaviourRegistry::discoverAllToTree() {
    QJsonObject paths = discoverAll();
    QJsonArray root;
    QMap<QString, QJsonObject> categoryNodes;

    QStringList pathKeys = paths.keys();
    for (const QString& key : pathKeys) {
        QStringList keySplit = key.split("/");
        if (keySplit.isEmpty()) continue;

        QString category = keySplit[0];
        if (!categoryNodes.contains(category)) {
            QJsonObject catNode;
            catNode["text"] = category;
            catNode["expanded"] = true;
            catNode["children"] = QJsonArray();
            categoryNodes[category] = catNode;
        }

        if (keySplit.size() > 1) {
            QJsonObject itemNode;
            itemNode["text"]   = keySplit.mid(1).join("/");
            itemNode["isLeaf"] = true;

            // QJsonValue::toArray() returns a copy, so we must read–modify–write
            QJsonArray children = categoryNodes[category]["children"].toArray();
            children.append(itemNode);
            categoryNodes[category]["children"] = children;
        }
    }

    for (const auto& node : categoryNodes) {
        root.append(node);
    }

    return root;
}
