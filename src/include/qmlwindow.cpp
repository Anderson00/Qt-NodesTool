#include "qmlwindow.h"
#include <QQuickView>
#include <QMessageBox>
#include <QGuiApplication>
#include <QSettings>
#include <QtQuickWidgets/QQuickWidget>
#include <QtQml/QQmlApplicationEngine>
#include <QtQml/QQmlContext>
#include <QtQml/QQmlComponent>

QMLWindow::QMLWindow(QWidget *parent, const QUrl& qmlUrl) : QMainWindow(parent)
{
    this->m_view = new QQuickView(this->windowHandle());

    if(qmlUrl.isValid()){
        this->view()->rootContext()->setContextProperty("window", this);
        this->m_view->setSource(qmlUrl);
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

void QMLWindow::setQMLSourceUrl(const QUrl &url)
{
    this->m_view->setSource(url);
}

QQuickView *QMLWindow::view()
{
    return this->m_view;
}
