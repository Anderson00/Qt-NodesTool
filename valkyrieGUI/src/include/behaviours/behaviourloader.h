#ifndef BEHAVIOURLOADER_H
#define BEHAVIOURLOADER_H

#include <QObject>
#include <QList>
#include <QDir>

#include "behaviours.h"

//namespace behaviour {
//namespace category {
//QString tag = "Debug";
//QString common = "Common";
//QString conditional = "Conditional";
//QString connections = "Connections";

//};
//};


class BehaviourLoader : public QObject
{
    Q_OBJECT
public:
    static BehaviourLoader* instance();

    Behaviours *loadBehaviour(const QString identity);
    QMap<QString, QMap<QString, QMap<QString, QString>>> discoverAll();

signals:

private:
    static BehaviourLoader *m_instance;
    explicit BehaviourLoader(QObject *parent = nullptr);

    void createDirsIfNotExists();

};

#endif // BEHAVIOURLOADER_H
