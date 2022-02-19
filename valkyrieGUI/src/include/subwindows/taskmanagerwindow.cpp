#include "taskmanagerwindow.h"
#include <QUrl>
#include "qmlwindow.h"
#include "qmlmdisubwindow.h"

TaskManagerWindow::TaskManagerWindow(QWidget *parent) :
    QMLMdiSubWindow(parent, QUrl("qrc:/subwindows/TaskManagerWindow.qml"))
{
    this->setWindowTitle("Task Manager");
    this->setMinimumSize(300, 200);
    this->resize(400, 400);

    this->showWindow(QVector<QMLWindow::PropertyPair>({
                                                          //QMLWindow::PropertyPair({"midClient", m_client})
                                                      }));
}

TaskManagerWindow::~TaskManagerWindow()
{

}

QString TaskManagerWindow::whoIAm()
{
    return "TaskManagerWindow";
}
