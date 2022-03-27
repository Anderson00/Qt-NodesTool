#include "behaviourloader.h"
#include <QFile>
#include <QDir>
#include <QDirIterator>
#include <QDebug>

#include "behaviours/common/fileopener.h"

BehaviourLoader *BehaviourLoader::m_instance = nullptr;

BehaviourLoader::BehaviourLoader(QObject *parent) : QObject(parent)
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

QMap<QString, QMap<QString, QMap<QString, QString>>> BehaviourLoader::discoverAll()
{
    //   DirPath   |   Name   |     {Key    , Value}
    QMap<QString, QMap<QString, QMap<QString, QString>>> result;
    QDir dir("Behaviours");
    QFileInfoList infos = dir.entryInfoList();

    typedef QMap<QString, QMap<QString, QString>> MapInfo;
    typedef QMap<QString, QString> IndividualInfo;


    FileOpener fileOpener;
    fileOpener.loadConnections();
    qDebug() << fileOpener.outputConns().keys().at(3);

    result["Debug/common"] = MapInfo({
                                         {"FileLoader", FileOpener::static_infos()},
                                         {"FileTest", IndividualInfo({})}
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
