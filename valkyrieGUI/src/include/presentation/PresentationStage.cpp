#include "PresentationStage.h"

PresentationStage::PresentationStage(QObject* parent) : QObject(parent) {}

QJsonObject PresentationStage::toJson() const
{
    QJsonObject obj;
    obj["id"]     = id;
    obj["name"]   = name;
    obj["worldX"] = worldX;
    obj["worldY"] = worldY;
    obj["worldW"] = worldW;
    obj["worldH"] = worldH;
    obj["zoom"]   = zoom;
    obj["notes"]  = notes;
    return obj;
}

PresentationStage* PresentationStage::fromJson(const QJsonObject& obj, QObject* parent)
{
    auto* s = new PresentationStage(parent);
    s->id     = obj.value("id").toString();
    s->name   = obj.value("name").toString();
    s->worldX = obj.value("worldX").toDouble(0);
    s->worldY = obj.value("worldY").toDouble(0);
    s->worldW = obj.value("worldW").toDouble(800);
    s->worldH = obj.value("worldH").toDouble(600);
    s->zoom   = obj.value("zoom").toDouble(-1);
    s->notes  = obj.value("notes").toString();
    return s;
}
