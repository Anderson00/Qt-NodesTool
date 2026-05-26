#ifndef KEYVALUEINPUT_H
#define KEYVALUEINPUT_H

#include <QObject>
#include <QJsonObject>
#include <QVariantList>
#include <behaviours/behaviours.h>

class KeyValueInput : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString keyText  READ keyText  WRITE setKeyText  NOTIFY keyTextChanged)
    Q_PROPERTY(double  valueNum READ valueNum WRITE setValueNum NOTIFY valueNumChanged)
    Q_PROPERTY(int     indexNum READ indexNum WRITE setIndexNum NOTIFY indexNumChanged)
    Q_PROPERTY(bool    autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit KeyValueInput(QObject *parent = nullptr);

    void onPinsReady() override;

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString keyText()  const;
    double  valueNum() const;
    int     indexNum() const;
    bool    autoSend() const;

public slots:
    void send();
    void trigger();
    void setKeyText(const QString& key);
    void setValueNum(double value);
    void setIndexNum(int index);
    void setAutoSend(bool enabled);

signals:
    void outputLabelValue(QString label, double value);  // OUTPUT PORT — (label, value)
    void outputIndexValue(int index, double value);      // OUTPUT PORT — (index, value)
    void outputString(QString value);                    // OUTPUT PORT — key string
    void outputValue(double value);                      // OUTPUT PORT — numeric value
    void outputData(QVariantList data);                  // OUTPUT PORT — universal [key, value]

    void keyTextChanged();
    void valueNumChanged();
    void indexNumChanged();
    void autoSendChanged();

private:
    QString m_keyText;
    double  m_valueNum = 0.0;
    int     m_indexNum = 0;
    bool    m_autoSend = false;
};

#endif // KEYVALUEINPUT_H
