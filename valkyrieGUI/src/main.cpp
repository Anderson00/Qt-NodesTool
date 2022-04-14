#include <QDebug>
#include <QApplication>

#include "include/mainwindow.h"
//#include <unicorn/unicorn.h>
//#include <capstone/capstone.h>
//#include <retdec/fileformat/fileformat.h>
#include <Qaterial/Qaterial.hpp>

int main(int argc, char **argv)
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QApplication a(argc, argv);
    // Load Qaterial.
    qaterial::loadQmlResources();
    qaterial::registerQmlTypes();

    MainWindow w;
    w.show();
    a.exec();

    return 0;
}
