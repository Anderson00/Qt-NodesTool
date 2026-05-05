#include "randomgeneratorviewer.h"
#include <random>

RandomGeneratorViewer::RandomGeneratorViewer(QObject *parent)
{
    this->setWidth(200);
    this->setHeight(200);
    this->setContentHeight(200);
    this->setQmlBodyUrl("qrc:/behaviours/common/RandomGeneratorViewer.qml");
    this->addInputOutputExclusion(QList<QString>({
                                                    "genNewNumber(double,double)"
                                                 }));
}

QMap<QString, QVariant> RandomGeneratorViewer::loadInfos()
{
    return RandomGeneratorViewer::static_infos();
}

QMap<QString, QVariant> RandomGeneratorViewer::static_infos()
{
    return QMap<QString, QVariant>({
                                       {"name", "RandomGeneratorViewer"},
                                       {"type", Behaviours::Type::CPP},
                                       {"className", "RandomGeneratorViewer"},
                                       {"desc", "Generate Random Values"},
                                       {"inputs_count", "1"},
                                       {"outputs_count", "1"}
                                   });
}

double RandomGeneratorViewer::genNewNumber(double min, double max)
{
    std::random_device rd;  // Will be used to obtain a seed for the random number engine
    std::mt19937 gen(rd()); // Standard mersenne_twister_engine seeded with rd()
    std::uniform_real_distribution<> dis(min, max);
    this->m_currentNumber = dis(gen);
    emit currentNumber(this->m_currentNumber);
    return this->m_currentNumber;
}
