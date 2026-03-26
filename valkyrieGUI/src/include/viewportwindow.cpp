#include "viewportwindow.h"
#include "behaviours/behaviourloader.h"
#include <QUuid>

ViewPortWindow::ViewPortWindow(QWidget *parent) :
    QMLWindow(parent, QUrl("qrc:/subwindows/ViewPortWindow.qml"))
{
    this->m_frameTimer = new QTimer(this);
    this->m_frameTimer->setTimerType(Qt::PreciseTimer);
    this->m_frameTimer->setInterval(1000);

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

bool ViewPortWindow::showFps()
{
    return this->m_showFps;
}

void ViewPortWindow::setShowFps(bool state)
{
    this->m_showFps = state;
    emit showFpsChanged();

    disconnect(this->m_timerTriggerConn);
    disconnect(this->m_frameSwappedConn);

    if(state == true){
        this->m_timerTriggerConn = connect(this->m_frameTimer, &QTimer::timeout, [&](){
            this->setFpsCount(m_frameCount);
            m_frameCount = 0;
        });

        this->m_frameSwappedConn = connect(this->view(), &QQuickView::frameSwapped, [&](){
            this->m_frameCount++;
        });

        this->m_frameTimer->start();
    } else {
        this->m_frameTimer->stop();
    }
}

int ViewPortWindow::fpsCount()
{
    return this->m_fpsCount;
}

void ViewPortWindow::setFpsCount(int value)
{
    this->m_fpsCount = value;
    emit fpsCountChanged();
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
