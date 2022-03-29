#ifndef FILEOPENER_H
#define FILEOPENER_H

#include <QString>
#include <QByteArray>
#include <QMap>
#include <QFile>
#include <behaviours/behaviours.h>

class FileOpener : public Behaviours
{
    Q_OBJECT
public:
    FileOpener();

    static QMap<QString, QVariant> static_infos();

public slots:
    void openFile(QString filePath);

signals:
    void output(QByteArray bytes);
};

#endif // FILEOPENER_H
