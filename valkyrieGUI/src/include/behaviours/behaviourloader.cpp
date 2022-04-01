#include "behaviourloader.h"
#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QDebug>
#include <QJsonArray>

#include "behaviours/common/fileopener.h"

BehaviourLoader *BehaviourLoader::m_instance = nullptr;

BehaviourLoader::BehaviourLoader(QObject *parent) : QObject(parent),
    m_treeModelPaths(new qaterial::TreeModel(this))
{
    createDirsIfNotExists();
    discoverAll();
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

Behaviours *BehaviourLoader::loadBehaviour(const QString identity)
{
    return nullptr;
}

QJsonObject BehaviourLoader::discoverAll()
{
    //   DirPath   |   Name   |     {Key    , Value}
    QJsonObject result;
    QDir dir("Behaviours");
    QFileInfoList infos = dir.entryInfoList();

    FileOpener fileOpener;
    fileOpener.loadConnections();
    qDebug() << fileOpener.inputConns().keys().size();

    result["Debug/common"] = QJsonArray({
                                            QJsonObject::fromVariantMap(QVariantMap(FileOpener::static_infos()))
                                        });

    QDirIterator it("Behaviours", QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QFileInfo fileInfo(it.next());
        if(fileInfo.isFile()){
            //result.dirName();
            //qDebug() << fileInfo.dir().dirName();

        }
    }

    return result;
}

qaterial::TreeElement* BehaviourLoader::discoverAllToTree()
{
    QJsonObject paths = discoverAll();

    qaterial::TreeElement *root = new qaterial::TreeElement(this);

    QStringList pathKeys = paths.keys();
    for(QString key : pathKeys){
        QStringList keySplit = key.split("/");
        if(keySplit.length() > 0){
            qaterial::TreeElement *element = new qaterial::TreeElement(m_treeModelPaths);
            element->setText(keySplit[0]);
            root->append(element);
            this->m_treeModelPaths->append(element);
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
