#include "taskmanagerwindow.h"
#include <QUrl>
#include "qmlwindow.h"
#include "qmlmdisubwindow.h"

#ifdef Q_OS_WIN
//Time conversion
static __int64 file_time_2_utc(const FILETIME* ftime)
{
    LARGE_INTEGER li;

    li.LowPart = ftime->dwLowDateTime;
    li.HighPart = ftime->dwHighDateTime;
    return li.QuadPart;
}
//Get CPU cores
static int get_processor_number()
{
    SYSTEM_INFO info;
    GetSystemInfo(&info);
    return (int)info.dwNumberOfProcessors;
}

static HANDLE hProcess = NULL;

//Get process CPU usage
int get_cpu_usage(int pid)
{
    //cpu quantity
    static int processor_count_ = -1;
    //Last time
    static __int64 last_time_ = 0;
    static __int64 last_system_time_ = 0;

    FILETIME now;
    FILETIME creation_time;
    FILETIME exit_time;
    FILETIME kernel_time;
    FILETIME user_time;
    __int64 system_time;
    __int64 time;
    __int64 system_time_delta;
    __int64 time_delta;

    int cpu = -1;

    if(processor_count_ == -1)
    {
        processor_count_ = get_processor_number();
    }

    GetSystemTimeAsFileTime(&now);

    if(hProcess == NULL)
        hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, pid);
    if (!GetProcessTimes(hProcess, &creation_time, &exit_time, &kernel_time, &user_time))
    {
        return -1;
    }
    system_time = (file_time_2_utc(&kernel_time) + file_time_2_utc(&user_time)) / processor_count_;
    time = file_time_2_utc(&now);

    if ((last_system_time_ == 0) || (last_time_ == 0))
    {
        last_system_time_ = system_time;
        last_time_ = time;
        return -1;
    }

    system_time_delta = system_time - last_system_time_;
    time_delta = time - last_time_;

    if (time_delta == 0)
        return -1;

    cpu = (int)((system_time_delta * 100 + time_delta / 2) / time_delta);
    last_system_time_ = system_time;
    last_time_ = time;
    return cpu;
}

#endif

TaskManagerWindow::TaskManagerWindow(QWidget *parent) :
    QMLMdiSubWindow(parent, QUrl("qrc:/subwindows/TaskManagerWindow.qml")),
    m_numProcessors(0)
{
    this->setWindowTitle("Task Manager");
    this->setMinimumSize(300, 200);
    this->resize(400, 400);

    init();

    this->showWindow(QVector<QMLWindow::PropertyPair>({
                                                          QMLWindow::PropertyPair({"taskManager", this})
                                                      }));
}

TaskManagerWindow::~TaskManagerWindow()
{
#ifdef Q_OS_WIN
    CloseHandle(hProcess);
    hProcess = NULL;
#endif
}

QString TaskManagerWindow::whoIAm()
{
    return "TaskManagerWindow";
}

void TaskManagerWindow::init()
{

}

double TaskManagerWindow::totalUsage()
{
#ifdef Q_OS_WIN

    return get_cpu_usage(GetCurrentProcessId());

#endif
    return 0.0;
}
