#include "behaviours.h"

#include <QDebug>

Behaviours::Behaviours(QObject *parent) : QObject(parent)
{
    this->m_x = 0;
    this->m_y = 0;
}

QMap<QString, QVariant> Behaviours::static_infos()
{
    return QMap<QString, QVariant>();
}

void Behaviours::loadConnections()
{
    const QMetaObject *metaObjectExclude = this->metaObject();

    int methodCountExclude = metaObjectExclude->methodCount();
    for(int index = 0; index < methodCountExclude; index++){
        QMetaMethod metaMethod = this->metaObject()->method(index);
        QString className = metaMethod.enclosingMetaObject()->className();

        if(className == "Behaviours" || className == "QObject"){
            switch (metaMethod.methodType()) {
            case QMetaMethod::Slot:
            case QMetaMethod::Signal:
                this->m_listOfExclusions.push_back(metaMethod.methodSignature());
                break;
            }
        }
    }

    const QMetaObject *metaObject = this->metaObject();
    int methodCount = metaObject->methodCount();
    for(int index = 0; index < methodCount; index++){
        QMetaMethod metaMethod = this->metaObject()->method(index);

        if(this->m_listOfExclusions.contains(metaMethod.methodSignature())) continue;

        if(metaMethod.methodType() == QMetaMethod::Slot){
            m_input_conns[metaMethod.methodSignature()] = new Connections(metaMethod, this);
        }else if(metaMethod.methodType() == QMetaMethod::Signal){
            m_output_conns[metaMethod.methodSignature()] = new Connections(metaMethod, this);
        }
    }
}

const QString &Behaviours::qmlBodyUrl()
{
    return this->m_qmlBodyUrl;
}

const QString &Behaviours::title()
{
    return this->m_title;
}

double Behaviours::width()
{
    return this->m_width;
}

double Behaviours::height()
{
    return this->m_height;
}

double Behaviours::x()
{
    return this->m_x;
}

double Behaviours::y()
{
    return this->m_y;
}

double Behaviours::contentWidth()
{
    return this->m_contentWidth;
}

double Behaviours::contentHeight()
{
    return this->m_contentHeight;
}

const QMap<QString, Connections*> &Behaviours::inputConns()
{
    return this->m_input_conns;
}

const QMap<QString, Connections*> &Behaviours::outputConns()
{
    return this->m_output_conns;
}

const QList<QString> &Behaviours::listOfExclusions()
{
    return this->m_listOfExclusions;
}

int Behaviours::qtdInputs()
{
    return this->m_input_conns.size();
}

int Behaviours::qtdOutputs()
{
    return this->m_output_conns.size();
}

Connections* Behaviours::getConnectionFromMethodSignature(const QString &signature)
{
    if(this->m_input_conns.contains(signature)){
        return this->m_input_conns[signature];
    }else if(this->m_output_conns.contains(signature)){
        return this->m_output_conns[signature];
    }

    return nullptr;
}

QList<QString> Behaviours::getInputsMethodSignature()
{
    return this->m_input_conns.keys();
}

QList<QString> Behaviours::getOutputsMethodSignature()
{
    return this->m_output_conns.keys();
}

void Behaviours::setInputConns(QMap<QString, Connections*> inputConns)
{
    this->m_input_conns = inputConns;
}

void Behaviours::setOutputConns(QMap<QString, Connections*> outputConns)
{
    this->m_output_conns = outputConns;
}

void Behaviours::addInputOutputExclusion(const QList<QString>& exclusionConnections)
{
    this->m_listOfExclusions.append(exclusionConnections);
}

void Behaviours::loaderOfInfosInFields()
{
    QMap<QString, QVariant> infos = loadInfos();
    this->m_title = infos["name"].toString();
}

void Behaviours::setQmlBodyUrl(const QString &newQmlBodyUrl)
{
    m_qmlBodyUrl = newQmlBodyUrl;
}

void Behaviours::setTitle(QString title)
{
    this->m_title = title;
    emit titleChanged(this->m_title);
}

void Behaviours::setWidth(double width)
{
    this->m_width = width;
    emit widthChanged(width);
}

void Behaviours::setHeight(double height)
{
    this->m_height = height;
    emit heightChanged(height);
}

void Behaviours::setContentWidth(double width)
{
    this->m_contentWidth = width;
    emit contentWidthChanged(width);
}

void Behaviours::setContentHeight(double height)
{
    this->m_contentHeight = height;
    emit contentHeightChanged(height);
}

void Behaviours::setX(double x)
{
    this->m_x = x;
    emit xChanged(x);
}

void Behaviours::setY(double y)
{
    this->m_y = y;
    emit yChanged(y);
}

QQuickItem *Behaviours::viewRect()
{
    return this->m_viewRectangle;
}

void Behaviours::setViewRectangle(QQuickItem *view)
{
    this->m_viewRectangle = view;
}

void Behaviours::start()
{
    loaderOfInfosInFields();
    loadConnections();
}
