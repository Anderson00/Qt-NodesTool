#include "bufferaccumulator.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(BufferAccumulator, "Buffer Accumulator", "Collect N values then emit as a batch list", "transform", 3, 2)

BufferAccumulator::BufferAccumulator(QObject *parent) : Behaviours(parent)
{
    setWidth(280);
    setHeight(220);
    setContentHeight(220);
    setQmlBodyUrl("qrc:/behaviours/transform/BufferAccumulator.qml");
    addInputOutputExclusion(QList<QString>({
        "internalCountChanged(int,int)",
        "internalFlushed(QVariantList)",
        "bufferSizeChanged()",
        "currentCountChanged()",
        "autoFlushChanged()"
    }));
}

void BufferAccumulator::onPinsReady()
{
    // inputs
    setPinTypeForSignature("push(QVariant)",  Connections::AnyType);
    setPinTypeForSignature("flush()",         Connections::FlowType);
    setPinTypeForSignature("reset()",         Connections::FlowType);
    // outputs
    setPinTypeForSignature("bufferFull(QVariantList)",    Connections::ArrayType);
    setPinTypeForSignature("bufferFlushed(QVariantList)", Connections::ArrayType);
}

QMap<QString, QVariant> BufferAccumulator::loadInfos() { return BufferAccumulator::static_infos(); }

QMap<QString, QVariant> BufferAccumulator::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",           "BufferAccumulator"},
        {"type",           Behaviours::Type::CPP},
        {"className",      "BufferAccumulator"},
        {"desc",           "Collect N values then emit as a batch list"},
        {"inputs_count",   "3"},
        {"outputs_count",  "2"}
    });
}

int  BufferAccumulator::bufferSize()   const { return m_bufferSize; }
int  BufferAccumulator::currentCount() const { return m_currentCount; }
bool BufferAccumulator::autoFlush()    const { return m_autoFlush; }

void BufferAccumulator::setBufferSize(int size)
{
    if (size < 1) size = 1;
    if (m_bufferSize == size) return;
    m_bufferSize = size;
    emit bufferSizeChanged();
}

void BufferAccumulator::setAutoFlush(bool enabled)
{
    if (m_autoFlush == enabled) return;
    m_autoFlush = enabled;
    emit autoFlushChanged();
}

void BufferAccumulator::push(QVariant value)
{
    m_buffer.append(value);
    m_currentCount = m_buffer.size();
    emit currentCountChanged();
    emit internalCountChanged(m_currentCount, m_bufferSize);

    if (m_autoFlush && m_currentCount >= m_bufferSize) {
        QVariantList list = m_buffer.toList();
        emit bufferFull(list);
        emit internalFlushed(list);
        m_buffer.clear();
        m_currentCount = 0;
        emit currentCountChanged();
        emit internalCountChanged(m_currentCount, m_bufferSize);
    }
}

void BufferAccumulator::flush()
{
    QVariantList list = m_buffer.toList();
    emit bufferFlushed(list);
    emit internalFlushed(list);
    m_buffer.clear();
    m_currentCount = 0;
    emit currentCountChanged();
    emit internalCountChanged(m_currentCount, m_bufferSize);
}

void BufferAccumulator::reset()
{
    m_buffer.clear();
    m_currentCount = 0;
    emit currentCountChanged();
    emit internalCountChanged(m_currentCount, m_bufferSize);
}

QJsonObject BufferAccumulator::saveState() const
{
    return {{"bufferSize", m_bufferSize}, {"autoFlush", m_autoFlush}};
}

void BufferAccumulator::loadState(const QJsonObject &state)
{
    if (state.contains("bufferSize")) setBufferSize(state["bufferSize"].toInt());
    if (state.contains("autoFlush"))  setAutoFlush(state["autoFlush"].toBool());
}
