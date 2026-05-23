#ifndef DATETIMEINPUT_H
#define DATETIMEINPUT_H

#include <QObject>
#include <QDateTime>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class DateTimeInput : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString dateStr  READ dateStr  NOTIFY dateStrChanged)
    Q_PROPERTY(QString format   READ format   WRITE setFormat   NOTIFY formatChanged)
    Q_PROPERTY(bool    autoSend READ autoSend WRITE setAutoSend NOTIFY autoSendChanged)

public:
    explicit DateTimeInput(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString dateStr()  const;
    QString format()   const;
    bool    autoSend() const;

public slots:
    void send();
    void trigger();
    void setDate(int year, int month, int day);
    void setTime(int hour, int minute, int second);
    void setFormat(const QString& fmt);
    void setAutoSend(bool enabled);

signals:
    void outputString(QString formatted);    // OUTPUT PORT
    void outputTimestamp(int unixTimestamp); // OUTPUT PORT

    void dateStrChanged();
    void formatChanged();
    void autoSendChanged();

private:
    QDateTime m_dateTime;
    QString   m_format   = "yyyy-MM-dd HH:mm:ss";
    bool      m_autoSend = false;
};

#endif // DATETIMEINPUT_H
