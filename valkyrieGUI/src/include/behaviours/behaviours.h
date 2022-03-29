#ifndef BEHAVIOURS_H
#define BEHAVIOURS_H

#include <QMetaMethod>
#include <QObject>
#include <QMap>
#include <QList>
#include <QString>

class Behaviours : public QObject
{
    Q_OBJECT
public:
    explicit Behaviours(QObject *parent = nullptr);

    static QMap<QString, QVariant> static_infos();

    virtual void loadConnections();

    const QMap<QString, QMetaMethod>& inputConns();
    const QMap<QString, QMetaMethod>& outputConns();

public slots:


signals:

protected:
    void setInputConns(QMap<QString, QMetaMethod> inputConns);
    void setOutputConns(QMap<QString, QMetaMethod> outputConns);

private:
    QString titulo;

    QMap<QString, QMetaMethod> m_input_conns;
    QMap<QString, QMetaMethod> m_output_conns;
};

#endif // BEHAVIOURS_H
