#include "behaviourloader.h"
#include "behaviourregistry.h"
#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QDebug>
#include <QJsonArray>

BehaviourLoader *BehaviourLoader::m_instance = nullptr;

BehaviourLoader::BehaviourLoader(QObject *parent) : QObject(parent),
    m_treeModelPaths(new qaterial::TreeModel(this))
{
    createDirsIfNotExists();

    // Cache the discovery result once at startup
    m_cachedDiscovery = BehaviourRegistry::instance().toDiscoveryJson();
}

void BehaviourLoader::createDirsIfNotExists()
{
    QDir().mkdir("Behaviours");
    QDir dir("Behaviours");
    dir.mkdir("Debug");
    dir.mkdir("Plugins");
}

BehaviourLoader *BehaviourLoader::instance()
{
    if(m_instance == nullptr){
        m_instance = new BehaviourLoader();
    }

    return m_instance;
}

Behaviours *BehaviourLoader::loadBehaviour(const QString &path, const QJsonObject infos)
{
    Q_UNUSED(path);

    // Delegate directly to the registry — O(1) lookup by className
    const QString className = infos["className"].toString();
    if (className.isEmpty()) {
        qWarning() << "[BehaviourLoader] Missing className in infos";
        return nullptr;
    }

    return BehaviourRegistry::instance().create(className);
}

QJsonObject BehaviourLoader::discoverAll()
{
    return m_cachedDiscovery;
}

void BehaviourLoader::invalidateCache()
{
    m_cachedDiscovery = BehaviourRegistry::instance().toDiscoveryJson();
}

qaterial::TreeElement* BehaviourLoader::discoverAllToTree()
{
    QJsonObject paths = discoverAll();

    qaterial::TreeElement *root = new qaterial::TreeElement(this);

    QMap<QString, qaterial::TreeElement*> roots;

    QStringList pathKeys = paths.keys();
    for(QString key : pathKeys){
        QStringList keySplit = key.split("/");
        if(keySplit.length() > 0){
            qaterial::TreeElement *element;
            if(roots.contains(keySplit[0])){
                element = roots[keySplit[0]];
            }else{
                element = new qaterial::TreeElement(m_treeModelPaths);
                roots[keySplit[0]] = element;
                root->append(element);
                this->m_treeModelPaths->append(element);
            }

            element->setText(keySplit[0]);

            if(keySplit.length() > 1){
                auto *newTree = new qaterial::TreeElement(m_treeModelPaths);
                element->append(newTree);

                for(int i = 0; i < keySplit.size(); i++){
                    newTree->setText(keySplit.join(";"));
                    keySplit.removeAt(0);
                    if(i < keySplit.size() - 1){
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
