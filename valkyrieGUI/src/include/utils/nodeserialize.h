#ifndef NODE_SERIALIZE_H
#define NODE_SERIALIZE_H

#include <QObject>
#include <QDateTime>
#include <QTimer>
#include <QKeySequence>
#include <QHash>
#include <QFile>
#include <QXmlStreamReader>
#include <QXmlStreamWriter>

namespace Presets {

class PresetsManager : public QObject{
    Q_OBJECT
public:
    explicit PresetsManager(QWidget *parent = nullptr);


};

class NodeSerialize {

public:
    NodeSerialize();
    virtual ~NodeSerialize() = default;

    virtual void save() = 0;
    virtual void load() = 0;
};
}


#endif // NODE_SERIALIZE_H
