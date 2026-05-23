#include "signalgenerator.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(SignalGenerator, "Signal Generator", "Generates sine, square, triangle, sawtooth, or noise waveforms", "Generators", 0, 1)

SignalGenerator::SignalGenerator(QObject *parent) : Behaviours(parent)
{
    this->setWidth(280);
    this->setHeight(400);
    this->setContentHeight(400);
    this->setQmlBodyUrl("qrc:/behaviours/common/SignalGenerator.qml");
}

QMap<QString, QVariant> SignalGenerator::loadInfos()
{
    return SignalGenerator::static_infos();
}

QMap<QString, QVariant> SignalGenerator::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "SignalGenerator"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "SignalGenerator"},
        {"desc",          "Waveform signal generator"},
        {"inputs_count",  "0"},
        {"outputs_count", "1"}
    });
}

void SignalGenerator::emitValue(double value)
{
    emit outputValue(value);
    emit outputString(QString::number(value));
}

QJsonObject SignalGenerator::saveState() const
{
    return QJsonObject();
}

void SignalGenerator::loadState(const QJsonObject&)
{
}
