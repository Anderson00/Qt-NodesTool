#ifndef UTILS_H
#define UTILS_H

#include <iostream>
#include <QFile>
#include <QString>
#include <QDateTime>
#include <QTextStream>
#include <src/controller/middlewarecontroller.h>

namespace mid {

static const QString filesDirName = "Input";

namespace convert {
MiddlewareController::OperationMode stdStringToOpMode(std::string mode);
MiddlewareController::OperationMode qStringToOpMode(QString mode);
}
namespace network {
const int TCP_SERVER_PORT = 6969;
}

namespace log {
static QFile log_file(QDateTime::currentDateTime().toString().replace(":","-").append(".txt"));

static void messageLogOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    if(!log_file.isOpen()){
        if(!mid::log::log_file.open(QIODevice::Append | QIODevice::Text)){
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
        buffer.append("[Info][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(context.line).append(", ").append(function).append(")");
        break;
    case QtWarningMsg:
        buffer.append("[Warning][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(context.line).append(", ").append(function).append(")");
        break;
    case QtCriticalMsg:
        buffer.append("[Critical][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(context.line).append(", ").append(function).append(")");
        break;
    case QtFatalMsg:
        buffer.append("[Fatal][").append(QDateTime::currentDateTime().toString(dateFormat)).append("] ").append(localMsg.constData()).append(" (").append(fileDirCompacted).append(":").append(context.line).append(", ").append(function).append(")");
        break;
    }

    std::cout << buffer.toStdString() << std::endl;
    out << buffer;
    out.flush();
}
}
}

#endif // UTILS_H
