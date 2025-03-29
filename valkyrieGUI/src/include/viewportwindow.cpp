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

        auto lambdaFun = [&, object](ConnectionModel * model){
            Behaviours * output = model->output();
            Behaviours * input = model->input();

            if(output == object){
                emit behaviourConnection(object, input);
            }else{
                emit behaviourConnection(object, output);
            }
        };

        QMetaObject::Connection outputConn = QObject::connect(object, &Behaviours::outputConnected, lambdaFun);
        QMetaObject::Connection inputConn = QObject::connect(object, &Behaviours::inputConnected, lambdaFun);

        QObject::connect(object, &Behaviours::destroyed, [=](){
            QObject::disconnect(outputConn);
            QObject::disconnect(inputConn);
        });

        object->start();
        emit this->behaviourAdded(object);
        return true;
    }

    return false;
}

bool ViewPortWindow::removeBehaviourFromUUID(const QString &uuid)
{
    return this->m_behaviours.remove(uuid);
}

bool ViewPortWindow::removeBehaviourObject(Behaviours *object)
{
    QString key = this->m_behaviours.key(object);
    delete object;
    return this->m_behaviours.remove(key);
}

Behaviours *ViewPortWindow::searchBehaviourFromUUID(const QString &uuid)
{
    return this->m_behaviours[uuid];
}

QString ViewPortWindow::getUUIDFromBehaviour(Behaviours *object)
{
    return this->m_behaviours.key(object);
}
