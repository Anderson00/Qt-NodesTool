#ifndef COMPONENTSVIEWER_H
#define COMPONENTSVIEWER_H

#include <behaviours/behaviours.h>

class ComponentsViewer: public Behaviours
{
public:
    explicit ComponentsViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

public slots:

signals:


private:


};

#endif // COMPONENTSVIEWER_H
