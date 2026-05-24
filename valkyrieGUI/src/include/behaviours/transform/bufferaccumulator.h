#ifndef BUFFERACCUMULATOR_H
#define BUFFERACCUMULATOR_H

#include <QObject>
#include <QJsonObject>
#include <QVector>
#include <QVariant>
#include <behaviours/behaviours.h>

class BufferAccumulator : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int  bufferSize   READ bufferSize   WRITE setBufferSize NOTIFY bufferSizeChanged)
    Q_PROPERTY(int  currentCount READ currentCount NOTIFY currentCountChanged)
    Q_PROPERTY(bool autoFlush    READ autoFlush    WRITE setAutoFlush  NOTIFY autoFlushChanged)

public:
    explicit BufferAccumulator(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int  bufferSize()   const;
    int  currentCount() const;
    bool autoFlush()    const;

    void setBufferSize(int size);
    void setAutoFlush(bool enabled);

public slots:
    void push(QVariant value);
    void flush();
    void reset();

signals:
    // Node outputs
    void bufferFull(QVariantList values);
    void bufferFlushed(QVariantList values);

    // Internal QML-only signals
    void internalCountChanged(int current, int max);
    void internalFlushed(QVariantList values);

    // Property notifiers
    void bufferSizeChanged();
    void currentCountChanged();
    void autoFlushChanged();

private:
    QVector<QVariant> m_buffer;
    int  m_bufferSize   = 10;
    int  m_currentCount = 0;
    bool m_autoFlush    = true;
};

#endif // BUFFERACCUMULATOR_H
