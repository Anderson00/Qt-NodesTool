#ifndef BEHAVIOURLOADER_H
#define BEHAVIOURLOADER_H

#include <QObject>
#include <QList>
#include <QDir>
#include <QJsonObject>

#include "behaviours.h"

#include "Qaterial/Navigation/TreeElement.hpp"
#include "Qaterial/Qaterial.hpp"

//namespace behaviour {
//namespace category {
//QString tag = "Debug";
//QString common = "Common";
//QString conditional = "Conditional";
//QString connections = "Connections";

//};
//};


class BehaviourLoader : public QObject
{
    Q_OBJECT
public:
    static BehaviourLoader* instance();

public slots:
    Behaviours *loadBehaviour(const QString &path, const QJsonObject infos);
    QJsonObject discoverAll();
    qaterial::TreeElement* discoverAllToTree();

signals:

private:
    static BehaviourLoader *m_instance;
    explicit BehaviourLoader(QObject *parent = nullptr);

    void createDirsIfNotExists();
    Behaviours *loadBehaviourAux(const QJsonObject infos);    
    Behaviours *loadBehaviourFromClassName(const QString &className);

    qaterial::TreeModel *m_treeModelPaths;

};

#endif // BEHAVIOURLOADER_H
