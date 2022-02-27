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

public slots:
    void setFullScreen(bool isFull);

signals:
    void fullScreenToogle();
};

#endif // VIEWPORTWINDOW_H
