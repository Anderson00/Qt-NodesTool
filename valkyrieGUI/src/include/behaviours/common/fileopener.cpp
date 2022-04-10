#include "fileopener.h"
#include <QTextStream>
#include <QDebug>

FileOpener::FileOpener(QObject *parent) : Behaviours(parent)
{
    this->setWidth(250);
    this->setHeight(100);
    this->setContentHeight(100);
    this->setQmlBodyUrl("qrc:/behaviours/common/FileOpener.qml");
    this->addInputOutputExclusion(QList<QString>({
                                               QString("openFile(QString)")
                                                 }));
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

void FileOpener::openFile(QString filePath)
{
    QFile file(filePath);

    if (!file.open(QIODevice::ReadWrite | QIODevice::Text))
        return;

    QTextStream in(&file);
    emit output(in.readAll().toUtf8());

    file.close();
}
