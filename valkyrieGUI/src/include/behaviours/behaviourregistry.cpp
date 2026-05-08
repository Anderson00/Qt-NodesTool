#include "behaviourregistry.h"
#include <QDebug>
#include <QDir>

BehaviourRegistry::BehaviourRegistry() : QObject(nullptr) {
    m_treeModelPaths = new qaterial::TreeModel(this);

    // Create plugin directories if they don't exist
    QDir().mkdir("Behaviours");
    QDir dir("Behaviours");
    dir.mkdir("Debug");
    dir.mkdir("Plugins");
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

qaterial::TreeElement* BehaviourRegistry::discoverAllToTree() {
    QJsonObject paths = discoverAll();

    qaterial::TreeElement *root = new qaterial::TreeElement(this);
    QMap<QString, qaterial::TreeElement*> roots;

    QStringList pathKeys = paths.keys();
    for (QString key : pathKeys) {
        QStringList keySplit = key.split("/");
        if (keySplit.length() > 0) {
            qaterial::TreeElement *element;
            if (roots.contains(keySplit[0])) {
                element = roots[keySplit[0]];
            } else {
                element = new qaterial::TreeElement(m_treeModelPaths);
                roots[keySplit[0]] = element;
                root->append(element);
                m_treeModelPaths->append(element);
            }

            element->setText(keySplit[0]);

            if (keySplit.length() > 1) {
                auto *newTree = new qaterial::TreeElement(m_treeModelPaths);
                element->append(newTree);

                for (int i = 0; i < keySplit.size(); i++) {
                    newTree->setText(keySplit.join(";"));
                    keySplit.removeAt(0);
                    if (i < keySplit.size() - 1) {
                        auto *newTreeNext = new qaterial::TreeElement(m_treeModelPaths);
                        newTree->append(newTreeNext);
                        newTree = newTreeNext;
                    }
                }
            }
        }
    }

    return root->children();
}
