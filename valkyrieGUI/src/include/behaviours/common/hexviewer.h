#ifndef HEXVIEWER_H
#define HEXVIEWER_H

#include <QJsonObject>
#include <QJsonArray>
#include <behaviours/behaviours.h>

class HexViewer : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int hexColumns READ hexColumns WRITE setHexColumns NOTIFY hexColumnsChanged)
public:
    explicit HexViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    int hexColumns();

    void setHexColumns(int hexColumns);

public slots:
    void input(QByteArray bytes);

signals:
    void hexColumnsChanged(int newHexColumns);
    void viewOutput(QJsonArray);

private:
    int m_hexColumns;

};

#endif // HEXVIEWER_H
