#include <QDebug>
#include <QApplication>
#include <iostream>

#include "include/mainwindow.h"
//#include <unicorn/unicorn.h>
//#include <capstone/capstone.h>
//#include <retdec/fileformat/fileformat.h>
#include <Qaterial/Qaterial.hpp>
#include <model/tablemodel.h>
#include <model/globalproperties.h>

static QFile log_file(QDateTime::currentDateTime().toString().replace(":","-").append(".log"));

static void messageLogOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    if(!log_file.isOpen()){
        if(!log_file.open(QIODevice::Append | QIODevice::Text)){
            qDebug() << log_file.errorString();
            abort();
        }
    }

    QByteArray localMsg = msg.toLocal8Bit();
    const char *function = context.function ? context.function : "";
    QTextStream out(&log_file);

    QString dateFormat = "dd/MM/yyyy HH:mm:ss";
    QString fileDirCompacted(context.file);
    QString buffer("");

    switch (type) {
    case QtDebugMsg:
        buffer.append("[Debug][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        break;
    case QtInfoMsg:
        buffer.append("[Info][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        break;
    case QtWarningMsg:
        buffer.append("[Warning][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        break;
    case QtCriticalMsg:
        buffer.append("[Critical][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        break;
    case QtFatalMsg:
        buffer.append("[Fatal][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        break;
    }

    std::cout << buffer.toStdString() << std::endl;
    out << buffer;
    out.flush();
}

int main(int argc, char **argv)
{

    qInstallMessageHandler(messageLogOutput);

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QApplication a(argc, argv);
    // Load Qaterial.
    qaterial::loadQmlResources();
    qaterial::registerQmlTypes();

    //qmlRegisterType<TableModel>("TableModel", 1, 0, "TableModel");

    // Register GlobalProperties as singleton in QML
    qmlRegisterSingletonInstance("App.GlobalProperties", 1, 0, "GlobalProperties", GlobalProperties::instance());

    MainWindow w;
    w.show();
    a.exec();

    return 0;
}
