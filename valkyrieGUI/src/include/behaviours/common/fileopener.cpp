#include "fileopener.h"
#include <QTextStream>

FileOpener::FileOpener()
{

}

QMap<QString, QString> FileOpener::static_infos()
{
    return QMap<QString, QString>({
                                      {}
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
