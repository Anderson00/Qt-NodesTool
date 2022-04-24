#ifndef PROCESSESVIEWER_H
#define PROCESSESVIEWER_H

#include <behaviours/behaviours.h>

class ProcessesViewer : public Behaviours
{
    Q_OBJECT
public:
    ProcessesViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

public slots:

signals:

private:
    int m_hexColumns;

};

#endif // PROCESSESVIEWER_H
