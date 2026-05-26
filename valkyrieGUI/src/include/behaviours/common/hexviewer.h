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

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

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
