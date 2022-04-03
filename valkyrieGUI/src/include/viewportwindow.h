#ifndef VIEWPORTWINDOW_H
#define VIEWPORTWINDOW_H

#include <QObject>
#include <QHash>
#include <QWidget>
#include "behaviours/behaviours.h"
#include "qmlwindow.h"

class ViewPortWindow : public QMLWindow
{
    Q_OBJECT
public:
    explicit ViewPortWindow(QWidget *parent = nullptr);
    ~ViewPortWindow();

public slots:
    void setFullScreen(bool isFull);

signals:
    void fullScreenToogle();

private:
    //    UUID  , Behaviour
    QHash<QString, Behaviours> m_behaviours;
};

#endif // VIEWPORTWINDOW_H
