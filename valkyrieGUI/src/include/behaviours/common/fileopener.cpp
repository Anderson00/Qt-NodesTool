#include "fileopener.h"
#include <QTextStream>
#include <QDebug>
#include <QFileDialog>

FileOpener::FileOpener(QObject *parent) : Behaviours(parent)
{
    this->setWidth(250);
    this->setHeight(100);
    this->setContentHeight(150);
    this->setQmlBodyUrl("qrc:/behaviours/common/FileOpener.qml");
    this->addInputOutputExclusion(QList<QString>({
                                                     "openFile(QString)",
                                                     "chooseFile(QString,QString)"
                                                 }));

    QObject::connect(this, &FileOpener::outputConnected, [this](){
        this->openFile(this->m_filePath);
    });
}

QMap<QString, QVariant> FileOpener::loadInfos()
{
    return FileOpener::static_infos();
}

QMap<QString, QVariant> FileOpener::static_infos()
{
    return QMap<QString, QVariant>({
                                      {"name", "FileOpener"},
                                      {"type", Behaviours::Type::CPP},
                                      {"className", "FileOpener"},
                                      {"desc", "Open and manipulate files"},
                                      {"inputs_count", "0"},
                                      {"outputs_count", "1"}
                                   });
}

QJsonObject FileOpener::chooseFile(QString rootPath, QString filter)
{
    QJsonObject result;
    QString fileName = QFileDialog::getOpenFileName(nullptr,
        tr("Open Executable"), rootPath, filter);

    if(fileName.isEmpty())
        return result;

    result["filePath"] = fileName;
    QFileInfo info(fileName);
    if(info.isFile()){
        result["type"] = info.suffix();
    }else if(info.isDir()){
        result["type"] = "Dir";
    }
    result["size"] = info.size();
    result["fileName"] = info.fileName();

    m_filePath = fileName;
    openFile(fileName);

    return result;
}

void FileOpener::openFile(QString filePath)
{
    QFile file(filePath);

    if (!file.open(QIODevice::ReadWrite | QIODevice::Text))
        return;

    QTextStream in(&file);
    emit output(in.readAll().toUtf8());

    file.close();
}
