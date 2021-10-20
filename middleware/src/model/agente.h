#ifndef AGENTE_H
#define AGENTE_H

#include <QObject>

class Agente : public QObject
{
    Q_OBJECT
public:
    explicit Agente(QObject *parent = nullptr);

signals:

};

#endif // AGENTE_H
