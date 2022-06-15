#ifndef FILEOPENER_H
#define FILEOPENER_H

#include <QString>
#include <QJsonObject>
#include <QByteArray>
#include <QMap>
#include <QFile>
#include <behaviours/behaviours.h>

class FileOpener : public Behaviours
{
    Q_OBJECT
public:
    explicit FileOpener(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

public slots:
    QJsonObject chooseFile(QString rootPath, QString filter);
    void openFile(QString filePath);

signals:
    void output(QByteArray bytes);

private:
    QString m_filePath;
};

#endif // FILEOPENER_H
