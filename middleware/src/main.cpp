#include <QDebug>
#include <QCoreApplication>
#include "utils.h"

int main(int argc, char **argv){

    qInstallMessageHandler(mid::log::messageLogOutput);

    QCoreApplication app(argc, argv);


    return app.exec();
}
