#include "hexviewer.h"
#include <QJsonArray>

HexViewer::HexViewer(QObject *parent)
{
    this->m_hexColumns = 16;
    this->setWidth(500);
    this->setHeight(300);
    this->setContentHeight(150);
    this->setQmlBodyUrl("qrc:/behaviours/common/HexViewer.qml");
    this->addInputOutputExclusion(QList<QString>({
                                                     "hexColumnsChanged(int)",
                                                     "viewOutput(QJsonArray)"
                                                 }));
}

QMap<QString, QVariant> HexViewer::loadInfos()
{
    return HexViewer::static_infos();
}

QMap<QString, QVariant> HexViewer::static_infos()
{
    return QMap<QString, QVariant>({
                                       {"name", "HexViewer"},
                                       {"type", Behaviours::Type::CPP},
                                       {"className", "HexViewer"},
                                       {"desc", "Hex viewer"},
                                       {"inputs_count", "1"},
                                       {"outputs_count", "0"}
                                   });
}

int HexViewer::hexColumns()
{
    return this->m_hexColumns;
}

void HexViewer::setHexColumns(int hexColumns)
{
    this->m_hexColumns = hexColumns;
    emit hexColumnsChanged(hexColumns);
}

void HexViewer::input(QByteArray bytes)
{
    QJsonObject result;
    QJsonArray lines;
    QJsonArray arrayOfBytes;

    int count = 0;
    int countTotal = 0;
    for(char byte : bytes){
        arrayOfBytes.push_back(QString::number((int)byte, 16).toUpper().rightJustified(2, '0'));
        if(count == this->hexColumns() || countTotal+1 == bytes.count()){
            lines.push_back(QJsonObject({
                                            {"offset", QString::number(lines.count(), 16).toUpper().rightJustified(8, '0')},
                                            {"bytes", arrayOfBytes}
                                        }));
            arrayOfBytes = QJsonArray(); //clear
            count = 0;
        }else{
            count++;
        }
        countTotal++;
    }

    emit viewOutput(lines);
}
