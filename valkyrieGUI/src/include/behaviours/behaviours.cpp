#include "behaviours.h"

#include <QDebug>
#include <model/connectionmodel.h>
#include "behaviours/typecoercions.h"
#include "utils/toastmanager.h"

Behaviours::Behaviours(QObject *parent) : QObject(parent)
{
    this->m_x = 0;
    this->m_y = 0;
    this->m_nodeTheme = new NodeTheme(this);
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
            m_input_conns[metaMethod.methodSignature()] = new Connections(this, metaMethod, this);
        }else if(metaMethod.methodType() == QMetaMethod::Signal){
            m_output_conns[metaMethod.methodSignature()] = new Connections(this, metaMethod, this);
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

bool Behaviours::isConnectionCompatible(const QString &sender, Behaviours *target, const QString &receiver)
{
    Connections *connections = this->getConnectionFromMethodSignature(sender);
    Connections *outputConn = target ? target->getConnectionFromMethodSignature(receiver) : nullptr;

    if (connections == nullptr || outputConn == nullptr)
        return false;

    // ── PinType semantic check ──────────────────────────────────────────────
    // Reject connections between incompatible typed pins before doing the
    // heavier Qt signature check. AnyType on either side always passes.
    if (!Connections::arePinTypesCompatible(connections->pinType(), outputConn->pinType())) {
        ToastManager::instance()->show(
            tr("Pin type mismatch: cannot connect %1 → %2")
                .arg(sender, receiver),
            "error");
        return false;
    }

    QMetaMethod signalMethod, slotMethod;
    if (connections->methodType() == Connections::Signal && outputConn->methodType() == Connections::Slot) {
        signalMethod = connections->metaMethod();
        slotMethod   = outputConn->metaMethod();
    } else if (connections->methodType() == Connections::Slot && outputConn->methodType() == Connections::Signal) {
        signalMethod = outputConn->metaMethod();
        slotMethod   = connections->metaMethod();
    } else {
        return false;
    }

    // ── Exact type match ────────────────────────────────────────────────────
    if (QMetaObject::checkConnectArgs(signalMethod.methodSignature().constData(),
                                      slotMethod.methodSignature().constData())) {
        return true;
    }

    // ── Coercible type match (int ↔ double etc.) ────────────────────────────
    const QByteArray srcParams = TypeCoercions::extractParams(signalMethod.methodSignature());
    const QByteArray dstParams = TypeCoercions::extractParams(slotMethod.methodSignature());
    return TypeCoercions::isCoercible(srcParams, dstParams);
}

bool Behaviours::addConnection(const QString &sender, Behaviours *target, const QString &receiver)
{
    qDebug() << "addConnection" << target << sender << receiver;

    Connections *connections = this->getConnectionFromMethodSignature(sender);
    if(connections != nullptr){
        qDebug() << connections;
        Connections *outputConn = target->getConnectionFromMethodSignature(receiver);
        if(outputConn != nullptr){
            // Check compatibility
            if (!this->isConnectionCompatible(sender, target, receiver)) {
                qDebug() << "Incompatible connection parameters between" << sender << "and" << receiver;
                return false;
            }

            ConnectionModel *model = connections->addConnection(target, outputConn->metaMethod());
            if(model != nullptr){
                if(isInputMethodSignature(sender)){
                    emit inputConnected(model);
                    target->outputConnected(model);
                }else if(isOutputMethodSignature(sender)){
                    emit outputConnected(model);
                    target->inputConnected(model);
                }//else //TODO: ????
            }
            return model != nullptr;
        }
    }
    return false;
}

QList<QString> Behaviours::getInputsMethodSignature()
{
    return this->m_input_conns.keys();
}

QList<QString> Behaviours::getOutputsMethodSignature()
{
    return this->m_output_conns.keys();
}

bool Behaviours::isInputMethodSignature(const QString &signature)
{

    return getInputsMethodSignature().contains(signature);
}

bool Behaviours::isOutputMethodSignature(const QString &signature)
{
    return getOutputsMethodSignature().contains(signature);
}

 QList<Behaviours*> Behaviours::getAllBehavioursConnected()
{
    QList<Behaviours*> result;

    for(Connections* it : this->m_input_conns){
        for(ConnectionModel * connModel : it->getAllConnections()){

            if(connModel->input() != this)
                result.push_back(connModel->input());
            if(connModel->output() != this)
                result.push_back(connModel->output());
        }
    }

    for(Connections* it : this->m_output_conns){
        for(ConnectionModel * connModel : it->getAllConnections()){
            if(connModel->input() != this)
                result.push_back(connModel->input());
            if(connModel->output() != this)
                result.push_back(connModel->output());
        }
    }

    return result;
}

void Behaviours::setInputConns(QMap<QString, Connections*> inputConns)
{
    this->m_input_conns = inputConns;
}

void Behaviours::setOutputConns(QMap<QString, Connections*> outputConns)
{
    this->m_output_conns = outputConns;
}

void Behaviours::addOutputConn(QString outputName, Connections *outputConn)
{
    this->m_output_conns[outputName] = outputConn;
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

NodeTheme *Behaviours::nodeTheme()
{
    return this->m_nodeTheme;
}

QString Behaviours::behaviourPath() const  { return m_behaviourPath; }
QJsonObject Behaviours::behaviourInfos() const { return m_behaviourInfos; }

void Behaviours::setBehaviourPath(const QString& path)   { m_behaviourPath  = path; }
void Behaviours::setBehaviourInfos(const QJsonObject& i) { m_behaviourInfos = i; }

const QString &Behaviours::uuid() const { return m_uuid; }
void Behaviours::setUuid(const QString &uuid) { m_uuid = uuid; }

QJsonObject Behaviours::saveState() const {
    return {};
}

void Behaviours::loadState(const QJsonObject& state) {
    Q_UNUSED(state);
}

void Behaviours::setViewRectangle(QQuickItem *view)
{
    this->m_viewRectangle = view;
}

void Behaviours::start()
{
    loaderOfInfosInFields();
    loadConnections();
    onPinsReady();
}

int Behaviours::getPinType(const QString& signature) const
{
    if (auto* conn = m_input_conns.value(signature))
        return static_cast<int>(conn->pinType());
    if (auto* conn = m_output_conns.value(signature))
        return static_cast<int>(conn->pinType());
    return static_cast<int>(Connections::AnyType);
}

void Behaviours::setPinTypeForSignature(const QString& signature, int type)
{
    const auto pinType = static_cast<Connections::PinType>(type);
    if (auto* conn = m_input_conns.value(signature)) {
        conn->setPinType(pinType);
        return;
    }
    if (auto* conn = m_output_conns.value(signature)) {
        conn->setPinType(pinType);
    }
}
