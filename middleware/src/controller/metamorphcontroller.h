#ifndef METAMORPHCONTROLLER_H
#define METAMORPHCONTROLLER_H

#include <QObject>
#include <QHash>

#include "../metamorph/metamorphprocess.h"

class MetamorphController : public QObject
{
    Q_OBJECT
public:
    explicit MetamorphController(QObject *parent = nullptr);

signals:

private:
    QHash<QString, MetamorphProcess*> m_processes;
};

#endif // METAMORPHCONTROLLER_H
