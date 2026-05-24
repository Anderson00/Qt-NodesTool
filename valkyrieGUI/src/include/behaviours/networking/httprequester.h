#ifndef HTTPREQUESTER_H
#define HTTPREQUESTER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QMap>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include <behaviours/behaviours.h>

class HttpRequester : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(int lastStatus READ lastStatus NOTIFY lastStatusChanged)
    Q_PROPERTY(int timeout READ timeout WRITE setTimeout NOTIFY timeoutChanged)

public:
    explicit HttpRequester(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    bool isLoading() const;
    int  lastStatus() const;
    int  timeout() const;
    void setTimeout(int ms);

public slots:
    void get(QString url);
    void post(QString url, QString body);
    void put(QString url, QString body);
    void del(QString url);
    void setHeader(QString key, QString value);
    void cancel();

signals:
    // Node outputs
    void responseReceived(QString body);
    void errorOccurred(QString error);
    void statusCode(int code);

    // Internal QML-only signals
    void internalResponse(QString body);
    void internalError(QString err);
    void internalStatus(int code);

    // Property notifiers
    void isLoadingChanged();
    void lastStatusChanged();
    void timeoutChanged();

private:
    void sendRequest(const QString& method, const QString& url, const QString& body = QString());
    void setIsLoading(bool loading);
    void setLastStatus(int status);

    QNetworkAccessManager* m_manager;
    QNetworkReply*          m_reply;
    QMap<QString, QString>  m_headers;
    bool                    m_isLoading;
    int                     m_lastStatus;
    int                     m_timeout;
    QString                 m_lastUrl;
};

#endif // HTTPREQUESTER_H
