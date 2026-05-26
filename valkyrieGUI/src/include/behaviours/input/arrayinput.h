#ifndef ARRAYINPUT_H
#define ARRAYINPUT_H

#include <QObject>
#include <QVariantList>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class ArrayInput : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QVariantList items    READ items    NOTIFY itemsChanged)
    Q_PROPERTY(bool         autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit ArrayInput(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QVariantList items()    const;
    bool         autoSend() const;

public slots:
    void send();
    void trigger();
    Q_INVOKABLE void addItem(const QString& value);
    Q_INVOKABLE void removeItem(int index);
    Q_INVOKABLE void setItem(int index, const QString& value);
    Q_INVOKABLE void clearItems();
    void setAutoSend(bool enabled);

signals:
    void outputArray(QVariantList items);    // OUTPUT PORT — typed array
    void outputString(QString jsonString);   // OUTPUT PORT — JSON string
    void outputCount(int count);             // OUTPUT PORT — item count
    void outputData(QVariantList data);      // OUTPUT PORT — universal (same as outputArray)

    void itemsChanged();
    void autoSendChanged();

private:
    QVariantList m_items;
    bool         m_autoSend = false;
};

#endif // ARRAYINPUT_H
