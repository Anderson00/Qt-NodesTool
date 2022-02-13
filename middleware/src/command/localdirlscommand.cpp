#include "localdirlscommand.h"
#include <QDir>
#include <src/utils.h>
#include <QThread>

LocalDirLSCommand::LocalDirLSCommand(QObject *parent):
    Command("ls", parent)
{

}

void LocalDirLSCommand::execute(QJsonArray params)
{
    QThread::create([this, params](){
        QString pathDir;
        if(params.size() > 0){
            QVariant path = params.at(0).toVariant();
            pathDir = path.canConvert<QString>()? path.toString() : ".";
        }else{
            pathDir = ".";
        }

        QDir dir(pathDir);
        emit result(dir.entryList({"*.exe"}, QDir::Files | QDir::NoDot | QDir::NoDotDot));

        QThread::currentThread()->deleteLater();
    })->start();
}
