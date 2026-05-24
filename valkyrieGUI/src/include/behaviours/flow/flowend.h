#ifndef FLOWEND_H
#define FLOWEND_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class FlowEnd : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(int hitCount READ hitCount NOTIFY hitCountChanged)

public:
    explicit FlowEnd(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int hitCount() const { return m_hits; }

public slots:
    void trigger();
    void reset();

signals:
    void triggered();
    void hitCountChanged();

private:
    int m_hits = 0;
};

#endif // FLOWEND_H
