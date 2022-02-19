#ifndef TASKMANAGERWINDOW_H
#define TASKMANAGERWINDOW_H

#include <QObject>
#include "qmlwindow.h"
#include "qmlmdisubwindow.h"

#ifdef Q_OS_WIN
#include <windows.h>
#endif

class TaskManagerWindow : public QMLMdiSubWindow
{
    Q_OBJECT
public:
    explicit TaskManagerWindow(QWidget *parent = nullptr);
    ~TaskManagerWindow();

    QString whoIAm() override;

public slots:
    double totalUsage();

signals:

private:
    void init();

    unsigned long m_numProcessors;

#ifdef Q_OS_WIN
    HANDLE m_selfProccess = NULL;
    ULARGE_INTEGER lastCPU, lastSysCPU, lastUserCPU;
#endif

};

#endif // TASKMANAGERWINDOW_H
