#include "behaviours.h"

Behaviours::Behaviours(QObject *parent) : QObject(parent)
{

}

QMap<QString, QString> Behaviours::static_infos()
{
    return QMap<QString, QString>();
}

void Behaviours::loadConnections()
{
    const QMetaObject *metaObject = this->metaObject();
    int methodCount = metaObject->methodCount();
    for(int index = 0; index < methodCount; index++){
        QMetaMethod metaMethod = this->metaObject()->method(index);

        if(metaMethod.methodType() == QMetaMethod::Slot){
            m_input_conns[metaMethod.methodSignature()] = metaMethod;
        }else if(metaMethod.methodType() == QMetaMethod::Signal){
            m_output_conns[metaMethod.methodSignature()] = metaMethod;
        }
    }
}

const QMap<QString, QMetaMethod> &Behaviours::inputConns()
{
    return this->m_input_conns;
}

const QMap<QString, QMetaMethod> &Behaviours::outputConns()
{
    return this->m_output_conns;
}

void Behaviours::setInputConns(QMap<QString, QMetaMethod> inputConns)
{
    this->m_input_conns = inputConns;
}

void Behaviours::setOutputConns(QMap<QString, QMetaMethod> outputConns)
{
    this->m_output_conns = outputConns;
}

//QMap<QString, QString> Behaviours::infos()
//{
//    return QMap<QString, QString>({
//                                      {"category", "common"},
//                                      {"title", "FileLoader"},
//                                      {"description", "Load files and output bytes"},
//                                      {"inputs", "3"},
//                                      {"outputs", "3"}
//                                  });
//}
