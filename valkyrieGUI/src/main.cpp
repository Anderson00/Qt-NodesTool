#include <QDebug>
#include <QApplication>
#include <iostream>

#include "include/mainwindow.h"
#include <Qaterial/Qaterial.hpp>
#include <model/tablemodel.h>
#include <model/globalproperties.h>
#include <utils/toastmanager.h>
#include <utils/logmanager.h>
#include <utils/fastlinechart.h>
#include <behaviours/behaviourregistry.h>

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
        // Debug messages are not shown in the status bar (too noisy)
        break;
    case QtInfoMsg:
        buffer.append("[Info][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        LogManager::instance()->addEntry(msg, "info");
        break;
    case QtWarningMsg:
        buffer.append("[Warning][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        LogManager::instance()->addEntry(msg, "warning");
        break;
    case QtCriticalMsg:
        buffer.append("[Critical][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        LogManager::instance()->addEntry(msg, "error");
        break;
    case QtFatalMsg:
        buffer.append("[Fatal][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(QString::number(context.line)).append(", ").append(function).append(")\n");
        LogManager::instance()->addEntry(msg, "fatal");
        break;
    }

    std::cout << buffer.toStdString() << std::endl;
    out << buffer;
    out.flush();
}

int main(int argc, char **argv)
{

    // Ativar depuração em tempo de execução
    //qputenv("QSG_INFO", QByteArray("1"));
    //qputenv("QSG_VISUALIZE", QByteArray("overdraw"));
    //qputenv("QSG_RENDERER_DEBUG", QByteArray("batch"));
    //qputenv("QSG_RENDER_TIMING", QByteArray("1"));
    //qputenv("QSG_RHI_BACKEND", QByteArray("vulkan"));
    //qputenv("QSG_RHI_DEBUG_LAYER", QByteArray("1"));
    //qputenv("QSG_RHI_PREFER_SOFTWARE_RENDERER", QByteArray("1"));

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

    // Register ToastManager as singleton in QML
    qmlRegisterSingletonInstance("App.Toast", 1, 0, "ToastManager", ToastManager::instance());

    // Register LogManager as singleton in QML
    qmlRegisterSingletonInstance("App.Log", 1, 0, "LogManager", LogManager::instance());

    // Register BehaviourRegistry (node discovery + factory) as singleton in QML
    qmlRegisterSingletonType<BehaviourRegistry>("App.NodeRegistry", 1, 0, "NodeRegistry",
                                                 &BehaviourRegistry::qmlSingletonProvider);

    // Register FastLineChart — direct SGG renderer, replaces QtCharts in LineChartViewer
    qmlRegisterType<FastLineChart>("App.Widgets", 1, 0, "FastLineChart");

    MainWindow w;
    w.show();
    a.exec();

    return 0;
}
