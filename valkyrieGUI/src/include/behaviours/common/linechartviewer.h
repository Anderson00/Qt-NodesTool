#ifndef LINECHARTVIEWER_H
#define LINECHARTVIEWER_H

#include <QObject>
#include <behaviours/behaviours.h>

class LineChartViewer : public Behaviours
{
    Q_OBJECT
public:
    explicit LineChartViewer(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

public slots:
    void appendXY(double x, double y);
    void appendYAutoIncrementX(double y);
signals:
    void internalAppendXY(double x, double y);
    void internalappendYAutoIncrementX(double y);
private:

};

#endif // LINECHARTVIEWER_H
