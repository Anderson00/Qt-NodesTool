#ifndef VIEWPORTWINDOW_H
#define VIEWPORTWINDOW_H

#include <QObject>
#include <QWidget>
#include "qmlwindow.h"

class ViewPortWindow : public QMLWindow
{
    Q_OBJECT
public:
    explicit ViewPortWindow(QWidget *parent = nullptr);
    ~ViewPortWindow();

signals:

};

#endif // VIEWPORTWINDOW_H
