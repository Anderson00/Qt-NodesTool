#include "viewportwindow.h"
#include "behaviours/behaviourloader.h"

ViewPortWindow::ViewPortWindow(QWidget *parent) :
    QMLWindow(parent, QUrl("qrc:/subwindows/ViewPortWindow.qml"))
{

    this->showWindow(QVector<QMLWindow::PropertyPair>({
                                                          QMLWindow::PropertyPair({"viewPort", this}),
                                                          QMLWindow::PropertyPair({"behaviourLoader", BehaviourLoader::instance()})
                                                      }));
}

ViewPortWindow::~ViewPortWindow()
{

}

void ViewPortWindow::setFullScreen(bool isFull)
{
    emit this->fullScreenToogle();
}
