#include "mainwindow.h"
#include "./ui_mainwindow.h"

#include <sstream>
#include <iomanip>

#include <QQuickView>
#include <QMessageBox>
#include <QDebug>
#include <QLabel>
#include <QScrollArea>

#include "subwindows/debuggermain.h"
#include "subwindows/testconnectionwindow.h"
#include "subwindows/taskmanagerwindow.h"
#include "utils/xmlsavestate.h"
#include "model/globalproperties.h"
#include "model/presetmanager.h"
#include "model/thememanager.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
    , m_viewPort(new ViewPortWindow(this))
{
    ui->setupUi(this);

    // Add actions to MainWindow to enable shortcuts without menubar
    addAction(ui->actionFullscreen);
    addAction(ui->actionUndo);
    addAction(ui->actionRedo);
    addAction(ui->actionOpen);
    addAction(ui->actionSave);

    QObject::connect(m_viewPort, &ViewPortWindow::fullScreenToogle, this, &MainWindow::on_actionFullscreen_triggered);

    // Connect undo/redo shortcuts to viewport
    QObject::connect(ui->actionUndo, &QAction::triggered, m_viewPort, &ViewPortWindow::undo);
    QObject::connect(ui->actionRedo, &QAction::triggered, m_viewPort, &ViewPortWindow::redo);

    this->ui->mdiArea->setViewport(this->m_viewPort);

    xml::XMLSaveState::instance()->setQMdiArea(this->ui->mdiArea);

    ThemeManager* tm = ThemeManager::instance();

    // Mark as initialized BEFORE loading to prevent any animations
    tm->markInitialized();

    // Load last preset
    QString lastPresetId = GlobalProperties::instance()->lastPresetId();
    PresetManager* pm = PresetManager::instance();
    if (!lastPresetId.isEmpty()) {
        for (int i = 0; i < pm->count(); ++i) {
            if (pm->presetAt(i)->id() == lastPresetId) {
                pm->applyPreset(i);
                break;
            }
        }
    } else {
        // Load theme mode (light/dark) - if no preset was loaded, apply the mode
        ThemeManager::ThemeMode themeMode = GlobalProperties::instance()->isDarkMode()
            ? ThemeManager::ThemeMode::Dark
            : ThemeManager::ThemeMode::Light;
        tm->setThemeMode(themeMode);
    }

    // Load show fps setting
    bool showFps = GlobalProperties::instance()->showFps();
    ui->actionShow_fps->setChecked(showFps);
    m_viewPort->setShowFps(showFps);

    // Load grid preset (will be applied via QML binding to GlobalProperties)
    int gridSize = GlobalProperties::instance()->minWgrid();
    qDebug() << "[MainWindow] Loaded grid preset minWgrid:" << gridSize;

    // Mark theme as initialized (now it will save changes)
    ThemeManager::instance()->markInitialized();
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

void MainWindow::on_actionShow_fps_toggled(bool arg1)
{
    this->m_viewPort->setShowFps(arg1);
    GlobalProperties::instance()->setShowFps(arg1);
}

