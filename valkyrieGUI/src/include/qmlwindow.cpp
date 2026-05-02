#include "qmlwindow.h"
#include <QQuickView>
#include <QMessageBox>
#include <QGuiApplication>
#include <QSettings>
#include <QtQuickWidgets/QQuickWidget>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlComponent>
#include <QUuid>
#include "model/thememanager.h"
#include "model/subtheme.h"
#include "model/globalproperties.h"
#include "model/presetmanager.h"
#include "model/colorpreset.h"
#include "utils/workspacemanager.h"

QMLWindow::QMLWindow(QWidget *parent, const QUrl& qmlUrl) : QMainWindow(parent),
    m_qml_url(qmlUrl)
{
    this->m_view = new QQuickView(this->windowHandle());

    if(qmlUrl.isValid()){

        qmlRegisterSingletonType<ThemeManager>(
            "App.Theme",
            1, 0,
            "ThemeManager",
            ThemeManager::qmlSingletonProvider
        );

        qmlRegisterSingletonType<ThemeManager>(
            "App.Properties",
            1, 0,
            "GlobalProperties",
            GlobalProperties::qmlSingletonProvider
            );

        qmlRegisterSingletonType<PresetManager>(
            "App.Presets",
            1, 0,
            "PresetManager",
            PresetManager::qmlSingletonProvider
            );

        qmlRegisterUncreatableType<ColorPreset>(
            "App.Presets",
            1, 0,
            "ColorPreset",
            "ColorPreset is created by PresetManager"
            );

        qmlRegisterSingletonType<WorkspaceManager>(
            "App.Workspace",
            1, 0,
            "WorkspaceManager",
            WorkspaceManager::qmlSingletonProvider
            );

        m_subTheme = new SubTheme(QUuid::createUuid().toString(QUuid::WithoutBraces));
        ThemeManager::instance()->addSubTheme(m_subTheme);

        this->view()->rootContext()->setContextProperty("theme", m_subTheme);
        this->view()->rootContext()->setContextProperty("window", this);        
        this->view()->engine()->addImportPath("qrc:///");
        this->view()->engine()->addImportPath("components");
    }

    this->setCentralWidget(QWidget::createWindowContainer(this->m_view, this));
    this->setContentsMargins(0, 0, 0, 0);
    this->setMinimumSize(50, 50);
}

QMLWindow::~QMLWindow()
{
    ThemeManager::instance()->removeSubTheme(m_subTheme);
    delete m_subTheme;
    delete m_view;
}

void QMLWindow::changeEvent(QEvent *e)
{
    static Qt::WindowStates prevWinState = Qt::WindowNoState;
    if (e->type() == QEvent::WindowStateChange)
    {

        if(prevWinState != windowState()){
            if(windowState() & Qt::WindowMaximized){
                emit windowMaximizing(true);
            }else if(windowState() & Qt::WindowMinimized){
                emit windowMinimizing(true);
            }else if(windowState() & Qt::WindowFullScreen){
                emit windowFullScreen(true);
            }else{
                if((prevWinState == Qt::WindowMaximized)){
                    emit windowMaximizing(false);
                }else if((prevWinState == Qt::WindowMinimized)){
                    emit windowMinimizing(false);
                }else if((prevWinState == Qt::WindowFullScreen)){
                    emit windowFullScreen(false);
                }
            }
        }

        prevWinState = windowState();
    }

    QWidget::changeEvent(e);
}

void QMLWindow::closeEvent(QCloseEvent *event)
{
    emit closeWindow();
    QMainWindow::closeEvent(event);
}

QUrl QMLWindow::source()
{
    return this->m_view->source();
}

void QMLWindow::showWindow(const QVector<PropertyPair> &properties)
{
    setContextProperties(properties);
}

void QMLWindow::setContextProperties(const QVector<PropertyPair> &properties)
{
    for(const PropertyPair& pair : properties){
        this->view()->rootContext()->setContextProperty(pair.name, pair.obj);
    }
    setQMLSourceUrl(this->m_qml_url);
}

void QMLWindow::setContextProperty(const QString &ctx, QObject *obj)
{
    this->m_view->rootContext()->setContextProperty(ctx, obj);
    setQMLSourceUrl(this->m_qml_url);
}

void QMLWindow::setQMLSourceUrl(const QUrl &url)
{
    this->m_qml_url = url;
    this->m_view->setSource(url);
}

QQuickView *QMLWindow::view()
{
    return this->m_view;
}
