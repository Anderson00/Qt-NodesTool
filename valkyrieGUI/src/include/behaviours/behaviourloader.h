#ifndef BEHAVIOURLOADER_H
#define BEHAVIOURLOADER_H

#include <QObject>
#include <QList>
#include <QDir>
#include <QJsonObject>

#include "behaviours.h"

#include "Qaterial/Navigation/TreeElement.hpp"
#include "Qaterial/Qaterial.hpp"

class BehaviourLoader : public QObject
{
    Q_OBJECT
public:
    static BehaviourLoader* instance();

public slots:
    Behaviours *loadBehaviour(const QString &path, const QJsonObject infos);
    QJsonObject discoverAll();
    qaterial::TreeElement* discoverAllToTree();

    /// Force re-read from BehaviourRegistry (e.g. after loading a plugin DLL)
    void invalidateCache();

signals:

private:
    static BehaviourLoader *m_instance;
    explicit BehaviourLoader(QObject *parent = nullptr);

    void createDirsIfNotExists();

    qaterial::TreeModel *m_treeModelPaths;
    QJsonObject m_cachedDiscovery;
};

#endif // BEHAVIOURLOADER_H
