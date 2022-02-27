#include "qmlwindow.h"
#include <QQuickView>
#include <QMessageBox>
#include <QGuiApplication>
#include <QSettings>
#include <QtQuickWidgets/QQuickWidget>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlComponent>

QMLWindow::QMLWindow(QWidget *parent, const QUrl& qmlUrl) : QMainWindow(parent),
    m_qml_url(qmlUrl)
{
    this->m_view = new QQuickView(this->windowHandle());

    if(qmlUrl.isValid()){
        this->view()->rootContext()->setContextProperty("window", this);        
        this->view()->engine()->addImportPath("qrc:///");
    }

    this->setCentralWidget(QWidget::createWindowContainer(this->m_view, this));
    this->setContentsMargins(0, 0, 0, 0);
    this->setMinimumSize(50, 50);
}

QMLWindow::~QMLWindow()
{
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
