#include "testconnectionwindow.h"
#include <QVector>
#include "qmlwindow.h"

TestConnectionWindow::TestConnectionWindow(QWidget *parent) :
    m_client(new MidClient(this)),
    QMLMdiSubWindow(parent, QUrl("qrc:/subwindows/TestConnectionWindow.qml"))
{
    this->setWindowTitle("Test Connection");
    this->setMinimumSize(300, 200);
    this->resize(400, 400);

    this->m_client->connectToHost("127.0.0.1", 6969);

    this->showWindow(QVector<QMLWindow::PropertyPair>({
                                                          QMLWindow::PropertyPair({"midClient", m_client})
                                                      }));
}

TestConnectionWindow::~TestConnectionWindow()
{
    delete m_client;
}


QString TestConnectionWindow::whoIAm()
{
    return "TestConnectionWindow";
}
