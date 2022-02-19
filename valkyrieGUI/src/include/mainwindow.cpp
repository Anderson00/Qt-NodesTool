#include "mainwindow.h"
#include "./ui_mainwindow.h"

#include <sstream>
#include <iomanip>

#include <QQuickView>
#include <QMessageBox>
#include <QDebug>
#include <QLabel>

#include "subwindows/debuggermain.h"
#include "subwindows/testconnectionwindow.h"
#include "subwindows/taskmanagerwindow.h"
#include "utils/xmlsavestate.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    DebuggerMain *dMain = new DebuggerMain(this->ui->mdiArea);
    this->ui->mdiArea->addSubWindow(dMain);

    xml::XMLSaveState::instance()->setQMdiArea(this->ui->mdiArea);
    xml::XMLSaveState::instance()->addWidgetsToSave(dMain);
}

MainWindow::~MainWindow()
{
    xml::XMLSaveState::instance()->saveState();
    delete ui;
}


void MainWindow::on_actionExit_triggered()
{
    QApplication::exit();
}

void MainWindow::on_actionOpen_triggered()
{

}

void MainWindow::on_actionProgram_header_toggled(bool arg1)
{

}

void MainWindow::on_actionFullscreen_triggered()
{
    if(!this->isFullScreen()){
        ui->actionFullscreen->setIcon(QIcon(":/icons/fullscreen-exit.svg"));
        this->showFullScreen();
    }else{
        ui->actionFullscreen->setIcon(QIcon(":/icons/fullscreen.svg"));
        this->showNormal();
    }
}

void MainWindow::on_actionTest_Connection_triggered()
{
    TestConnectionWindow *testConn = new TestConnectionWindow(this->ui->mdiArea);
    this->ui->mdiArea->addSubWindow(testConn);
    testConn->setVisible(true);
}


void MainWindow::on_actionTask_Manager_triggered()
{
    if(this->m_taskManager == nullptr){
        this->m_taskManager = new TaskManagerWindow(this->ui->mdiArea);
        QObject::connect(this->m_taskManager, &QObject::destroyed, [this](){
            this->ui->actionTask_Manager->setEnabled(true);
            QObject::disconnect(this->m_taskManager);
            this->m_taskManager = nullptr;
        });
        this->ui->mdiArea->addSubWindow(m_taskManager);
        m_taskManager->setVisible(true);
        this->ui->actionTask_Manager->setEnabled(false);
    }else{
        this->ui->actionTask_Manager->setEnabled(true);
        this->ui->mdiArea->removeSubWindow(this->m_taskManager);
        delete m_taskManager;
        this->m_taskManager = nullptr;
    }
}

