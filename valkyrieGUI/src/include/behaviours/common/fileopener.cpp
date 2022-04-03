#include "fileopener.h"
#include <QTextStream>

FileOpener::FileOpener()
{
    this->setQmlBodyUrl(QUrl("qrc:/behaviours/common/FileOpener.qml"));
    this->addInputOutputExclusion(QList<QString>({
                                               QString("openFile(QString)")
                                           }));
}

QMap<QString, QVariant> FileOpener::static_infos()
{
    return QMap<QString, QVariant>({
                                      {"name", "FileOpener"},
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
