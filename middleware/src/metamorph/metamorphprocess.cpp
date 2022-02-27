#include "metamorphprocess.h"

MetamorphProcess::MetamorphProcess(QStringList args, QObject *parent) :
    QObject(parent),
    m_proc(new QProcess(this))
{
    this->m_args.append(args);

}

MetamorphProcess::~MetamorphProcess(){
    this->m_proc->terminate();
    this->m_proc->waitForFinished();
    // TODO: remove blocking event, impl garbage collector for assyncronous clean.
    delete this->m_proc;
}

void MetamorphProcess::doRequest(QJsonObject obj)
{

}
