#include "qmlmdisubwindow.h"
#include <QSettings>

QMLMdiSubWindow::QMLMdiSubWindow(QWidget *parent, const QUrl& source) : QMdiSubWindow(parent), m_window(new QMLWindow(this, source))
{
    this->setWidget(this->m_window->centralWidget());
    this->QMdiSubWindow::setAttribute(Qt::WA_DeleteOnClose);
    this->setMinimumSize(100, 100);
    this->m_window->setMinimumSize(100, 100);

    QObject::connect(this->m_window, &QMLWindow::closeWindow, [=](){
        qDebug() << "Janela fechada";
    });

    loadState();
}

QMLMdiSubWindow::~QMLMdiSubWindow()
{
    saveState();
    delete this->m_window;
}

QUrl QMLMdiSubWindow::source()
{
    return this->m_window->source();
}

void QMLMdiSubWindow::showWindow(const QVector<QMLWindow::PropertyPair> &properties)
{
    this->m_window->showWindow(properties);
}

void QMLMdiSubWindow::setContextProperty(const QString &ctx, QObject *obj)
{
    this->m_window->setContextProperty(ctx, obj);
}

void QMLMdiSubWindow::saveState()
{

}

void QMLMdiSubWindow::loadState()
{

}
