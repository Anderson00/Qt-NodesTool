#ifndef TASKMANAGERWINDOW_H
#define TASKMANAGERWINDOW_H

#include <QObject>
#include <QJsonObject>
#include "qmlwindow.h"
#include "qmlmdisubwindow.h"

#ifdef Q_OS_WIN
#include <windows.h>
#include <psapi.h>
#endif

class TaskManagerWindow : public QMLMdiSubWindow
{
    Q_OBJECT
public:
    explicit TaskManagerWindow(QWidget *parent = nullptr);
    ~TaskManagerWindow();

    QString whoIAm() override;

public slots:
    // Current Process
    double totalUsage();
    QJsonObject processMemoryCounters();

    // Global Memory
    unsigned long totalSystemMemoryUsage();
    unsigned long totalSystemMemory();

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
