#ifndef BEHAVIOURREGISTRY_H
#define BEHAVIOURREGISTRY_H

#include <QString>
#include <QMap>
#include <QList>
#include <QJsonObject>
#include <QJsonArray>
#include <functional>

class Behaviours;

/**
 * @brief Metadata describing a registered node type.
 *
 * Each Behaviour subclass populates one of these at static-init time
 * via the REGISTER_BEHAVIOUR macro. The registry uses it for both
 * factory instantiation and UI discovery.
 */
struct BehaviourMeta {
    QString className;
    QString displayName;
    QString description;
    QString category;     // e.g. "common", "logic", "cv/detection"
    int     inputsCount  = 0;
    int     outputsCount = 0;
    std::function<Behaviours*()> factory;

    /// Convert to the QJsonObject format expected by BehaviourLoader / NodesDrawer
    QJsonObject toJson() const {
        QJsonObject obj;
        obj["name"]          = displayName;
        obj["className"]     = className;
        obj["type"]          = 0; // Behaviours::CPP
        obj["desc"]          = description;
        obj["category"]      = category;
        obj["inputs_count"]  = QString::number(inputsCount);
        obj["outputs_count"] = QString::number(outputsCount);
        return obj;
    }
};

/**
 * @brief Global, thread-safe registry of all available Behaviour types.
 *
 * Nodes register themselves at static-init via the REGISTER_BEHAVIOUR macro.
 * BehaviourLoader delegates instantiation and discovery to this class.
 */
class BehaviourRegistry {
public:
    static BehaviourRegistry& instance();

    /// Register a node type. Returns true on success, false if className already exists.
    bool add(const BehaviourMeta& meta);

    /// Instantiate a Behaviour by className. Returns nullptr if unknown.
    Behaviours* create(const QString& className) const;

    /// Returns true if the given className is registered.
    bool contains(const QString& className) const;

    /// Get all registered metadata entries.
    QList<BehaviourMeta> allMeta() const;

    /// Get metadata for a specific category (e.g. "common")
    QList<BehaviourMeta> metaByCategory(const QString& category) const;

    /// Get all unique category names.
    QStringList categories() const;

    /**
     * @brief Build a QJsonObject keyed by "Debug/{category}" for
     *        backward-compatibility with discoverAll() consumers.
     */
    QJsonObject toDiscoveryJson() const;

private:
    BehaviourRegistry() = default;
    QMap<QString, BehaviourMeta> m_registry;
};

// ─── Auto-registration macro ────────────────────────────────────────────────
// Place in the .cpp file of each Behaviour subclass:
//
//   REGISTER_BEHAVIOUR(FileOpener, "File Opener", "Open and manipulate files", "common", 0, 1)
//
// The static bool triggers registration at program startup, before main().
// ─────────────────────────────────────────────────────────────────────────────
#define REGISTER_BEHAVIOUR(Class, DisplayName, Desc, Category, InCount, OutCount) \
    static bool _reg_##Class = BehaviourRegistry::instance().add({                \
        QStringLiteral(#Class),                                                   \
        QStringLiteral(DisplayName),                                              \
        QStringLiteral(Desc),                                                     \
        QStringLiteral(Category),                                                 \
        InCount,                                                                  \
        OutCount,                                                                 \
        []() -> Behaviours* { return new Class(); }                               \
    });

#endif // BEHAVIOURREGISTRY_H
