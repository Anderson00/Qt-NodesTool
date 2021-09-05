#include "xmlsavestate.h"

xml::XMLSaveState *xml::XMLSaveState::m_instance = nullptr;

xml::XMLSaveState::XMLSaveState(QObject *parent) : QObject(parent)
{
    setLogic(Logic::NoLogic);
    setSaveInterval();
}

xml::XMLSaveState::~XMLSaveState()
{
    if(this->m_timer != nullptr)
        delete m_timer;
}

xml::XMLSaveState *xml::XMLSaveState::instance()
{
    if(xml::XMLSaveState::m_instance == nullptr){
        xml::XMLSaveState::m_instance = new XMLSaveState();
    }
    return xml::XMLSaveState::m_instance;
}

void xml::XMLSaveState::setLogic(XMLSaveState::Logic logic)
{
    this->m_logic = logic;
    switch (this->m_logic) {
        case Logic::Interval:
            this->m_timer = new QTimer();
            this->m_timer->setInterval(this->m_intervalMsecs);
            QObject::connect(this->m_timer, SIGNAL(timeout()), this, SLOT(saveState()));
        break;
        case Logic::Shortcut:

        break;
        case Logic::IntervalAndShortcut:

        break;
        case Logic::NoLogic:

        break;
    }
}

void xml::XMLSaveState::setQMdiArea(QMdiArea *mdiArea)
{
    this->m_mdiArea = mdiArea;
}

void xml::XMLSaveState::setSaveInterval(int msecs)
{
    this->m_intervalMsecs = msecs;
}

QMLMdiSubWindow *xml::XMLSaveState::addWidgetsToSave(QMLMdiSubWindow *qmlSubWindows, std::function<QHash<QString, QString> (QMLMdiSubWindow *)> saveLogic)
{
    if(!this->m_qmlSubWindowsAndLogics.contains(qmlSubWindows)){
        this->m_qmlSubWindowsAndLogics[qmlSubWindows] = saveLogic;
        return qmlSubWindows;
    }

    return nullptr;
}

void xml::XMLSaveState::onShortcutExecuted(const QKeySequence &shortcutKeys)
{

}

void xml::XMLSaveState::saveState()
{
    //TODO: use of Threads
    QFile file("XMLSaveStates.xml");
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return; //TODO: throw exception or other logic

    QXmlStreamWriter xmlWriter(&file);
    xmlWriter.setAutoFormatting(true);
    xmlWriter.writeStartDocument();

    for(auto it = this->m_qmlSubWindowsAndLogics.begin(); it != this->m_qmlSubWindowsAndLogics.end(); it++){
        QHash<QString, QString> result = it.value()(it.key());
        xmlWriter.writeStartElement("QMLSubWindows");
            xmlWriter.writeStartElement(it.key()->whoIAm());
                for(auto itResult = result.begin(); itResult != result.end(); itResult++){
                    //TODO: implementar possibilidade do caller adicionar elementos com base na key com padrões
                    xmlWriter.writeAttribute(itResult.key(), itResult.value());
                }
            xmlWriter.writeEndElement();
        xmlWriter.writeEndElement();
    }

    xmlWriter.writeEndDocument();
    file.flush();
    file.close();
}
