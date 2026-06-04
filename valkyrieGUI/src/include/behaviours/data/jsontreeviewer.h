#ifndef JSONTREEVIEWER_H
#define JSONTREEVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QVariantList>
#include <behaviours/behaviours.h>

class JsonTreeViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int nodeCount   READ nodeCount   NOTIFY nodeCountChanged)
    Q_PROPERTY(int expandDepth READ expandDepth NOTIFY expandDepthChanged)

public:
    explicit JsonTreeViewer(QObject *parent = nullptr);

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int nodeCount()   const;
    int expandDepth() const;

public slots:
    void loadJson(QString json);
    void clear();
    void setExpandDepth(int depth);

signals:
    // Internal QML-only signals (no node outputs)
    void internalLoad(QVariantList treeModel);
    void internalClear();

    // Property notifiers
    void nodeCountChanged();
    void expandDepthChanged();

private:
    void flattenValue(const QString& key, const QJsonValue& val, int depth,
                      QVariantList& out) const;
    QVariantList buildFlatModel(const QJsonDocument& doc) const;

    QString  m_lastJson;
    int      m_nodeCount;
    int      m_expandDepth;
};

#endif // JSONTREEVIEWER_H
