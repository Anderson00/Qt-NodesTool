#include "behaviourloader.h"
#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QDebug>
#include <QJsonArray>

#include "behaviours/common/fileopener.h"
#include "behaviours/common/hexviewer.h"
#include "behaviours/logic/hub.h"

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

Behaviours *BehaviourLoader::loadBehaviourAux(const QJsonObject infos)
{
    if(infos.contains("type")){
        int typeInteger = infos["type"].toInt(-1);
        if(typeInteger == -1)
            return nullptr;
        Behaviours::Type type = static_cast<Behaviours::Type>(typeInteger);
        switch(type) {
        case Behaviours::CPP:
            if(infos.contains("className")){
                return loadBehaviourFromClassName(infos["className"].toString(""));
            }
            break;
        case Behaviours::DLL:
            break;
        case Behaviours::PYTHON:
            break;
        }
    }
    return nullptr;
}

Behaviours *BehaviourLoader::loadBehaviourFromClassName(const QString &className)
{
    if(className == "FileOpener"){
        return new FileOpener;
    }else if(className == "Hub"){
        return new Hub;
    }else if(className == "HexViewer"){
        return new HexViewer;
    }

    return nullptr;
}

Behaviours *BehaviourLoader::loadBehaviour(const QString &path, const QJsonObject infos)
{
    QJsonArray array = discoverAll()[path].toArray();
    if(!array.isEmpty()){
        for(QJsonValue value : array){
            if(value.isObject()){
                QJsonObject valueInfos = value.toObject();
                for(QString key : valueInfos.keys()){
                    if(infos.contains(key) && infos[key] == valueInfos[key]){
                        return loadBehaviourAux(infos);
                    }
                }
            }
        }
    }

    return nullptr;
}

QJsonObject BehaviourLoader::discoverAll()
{
    //   DirPath   |   Name   |     {Key    , Value}
    QJsonObject result;
    QDir dir("Behaviours");
    QFileInfoList infos = dir.entryInfoList();

    FileOpener fileOpener;
    fileOpener.start();
    qDebug() << fileOpener.inputConns().keys().size();

    result["Debug/common"] = QJsonArray({
                                            QJsonObject::fromVariantMap(QVariantMap(FileOpener::static_infos())),
                                            QJsonObject::fromVariantMap(QVariantMap(HexViewer::static_infos()))
                                        });

    result["Debug/logic"] = QJsonArray({
                                           QJsonObject::fromVariantMap(QVariantMap(Hub::static_infos()))
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
