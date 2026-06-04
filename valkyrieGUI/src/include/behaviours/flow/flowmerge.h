#ifndef FLOWMERGE_H
#define FLOWMERGE_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class FlowMerge : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString lastSource READ lastSource NOTIFY lastSourceChanged)
    Q_PROPERTY(int     mergeCount READ mergeCount NOTIFY mergeCountChanged)

public:
    explicit FlowMerge(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString lastSource() const { return m_lastSource; }
    int     mergeCount() const { return m_count; }

public slots:
    void triggerA();
    void triggerB();
    void triggerC();

signals:
    void execOut();
    void lastSourceChanged();
    void mergeCountChanged();

private:
    void fire(const QString& source);
    QString m_lastSource;
    int     m_count = 0;
};

#endif // FLOWMERGE_H
