#ifndef UTILS_H
#define UTILS_H

#include <QFile>
#include <QString>
#include <QDateTime>
#include <QTextStream>

namespace mid {
namespace network {
    const int TCP_SERVER_PORT = 6969;
}

namespace log {
static QFile log_file("middleware.txt");

static void messageLogOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    if(!log_file.isOpen()){
        if(!mid::log::log_file.open(QIODevice::Append | QIODevice::Text)){
            abort();
        }
    }

    QByteArray localMsg = msg.toLocal8Bit();
    const char *function = context.function ? context.function : "";
    QTextStream out(&log_file);

    QString dateFormat = "dd/MM/yyyy HH:mm:ss";
    QString fileDirCompacted(context.file);

    switch (type) {
    case QtDebugMsg:
        out << "[Debug][" << QDateTime::currentDateTime().toString(dateFormat) << "] " << localMsg.constData() << " (" << fileDirCompacted << ":" << context.line << ", " << function << ")\r\n";
        break;
    case QtInfoMsg:
        out << "[Info][" << QDateTime::currentDateTime().toString(dateFormat) << "] " << localMsg.constData() << "(" << fileDirCompacted << ":" << context.line << ", " << function << ")\r\n";
        break;
    case QtWarningMsg:
        out << "[Warning][" << QDateTime::currentDateTime().toString(dateFormat) << "] " << localMsg.constData() << "(" << fileDirCompacted << ":" << context.line << ", " << function << ")\r\n";
        break;
    case QtCriticalMsg:
        out << "[Critical][" << QDateTime::currentDateTime().toString(dateFormat) << "] " << localMsg.constData() << "(" << fileDirCompacted << ":" << context.line << ", " << function << ")\r\n";
        break;
    case QtFatalMsg:
        out << "[Fatal][" << QDateTime::currentDateTime().toString(dateFormat) << "] " << localMsg.constData() << "(" << fileDirCompacted << ":" << context.line << ", " << function << ")\r\n";
        break;
    }

    out.flush();
}
}
}

#endif // UTILS_H
