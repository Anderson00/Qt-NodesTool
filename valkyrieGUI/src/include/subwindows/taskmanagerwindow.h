#ifndef TASKMANAGERWINDOW_H
#define TASKMANAGERWINDOW_H

#include <QObject>
#include "qmlwindow.h"
#include "qmlmdisubwindow.h"

class TaskManagerWindow : public QMLMdiSubWindow
{
    Q_OBJECT
public:
    explicit TaskManagerWindow(QWidget *parent = nullptr);
    ~TaskManagerWindow();

    QString whoIAm() override;

signals:

private:
};

#endif // TASKMANAGERWINDOW_H
