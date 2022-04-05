#include "viewportwindow.h"
#include "behaviours/behaviourloader.h"
#include <QUuid>

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

QHash<QString, Behaviours *> ViewPortWindow::behaviours()
{
    return this->m_behaviours;
}

void ViewPortWindow::setFullScreen(bool isFull)
{
    emit this->fullScreenToogle();
}

bool ViewPortWindow::addBehaviour(const QString &path, const QJsonObject infos)
{
    QString uuid = QUuid::createUuid().toString(QUuid::WithoutBraces);
    Behaviours *object = BehaviourLoader::instance()->loadBehaviour(path, infos);
    if(object != nullptr){
        this->m_behaviours[uuid] = object;
        emit this->behaviourAdded(object);
        return true;
    }

    return false;
}
