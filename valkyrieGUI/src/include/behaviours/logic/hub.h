#ifndef HUB_H
#define HUB_H

#include <behaviours/behaviours.h>

class Hub : public Behaviours
{
    Q_OBJECT
public:
    explicit Hub(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

public slots:
    void input(QVariant variant);

signals:


private:

};

#endif // HUB_H
