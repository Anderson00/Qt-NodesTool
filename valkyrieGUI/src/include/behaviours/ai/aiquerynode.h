#ifndef AIQUERYNODE_H
#define AIQUERYNODE_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include <QJsonDocument>
#include <behaviours/behaviours.h>

class AIQueryNode : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString systemPrompt READ systemPrompt WRITE setSystemPrompt NOTIFY systemPromptChanged)
    Q_PROPERTY(QString model        READ model        WRITE setModel        NOTIFY modelChanged)
    Q_PROPERTY(int     maxTokens    READ maxTokens    WRITE setMaxTokens    NOTIFY maxTokensChanged)
    Q_PROPERTY(bool    isLoading    READ isLoading    NOTIFY isLoadingChanged)
    Q_PROPERTY(QString lastResponse READ lastResponse NOTIFY lastResponseChanged)

public:
    explicit AIQueryNode(QObject *parent = nullptr);

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString systemPrompt() const { return m_systemPrompt; }
    QString model()        const { return m_model; }
    int     maxTokens()    const { return m_maxTokens; }
    bool    isLoading()    const { return m_isLoading; }
    QString lastResponse() const { return m_lastResponse; }

    void setMaxTokens(int tokens);

public slots:
    void query(QString userPrompt);
    void setSystemPrompt(QString sp);
    void setModel(QString model);
    void cancel();
    void setApiKey(QString key);

signals:
    // Node outputs
    void responseReceived(QString text);
    void error(QString msg);
    void tokensUsed(int inputTokens, int outputTokens);

    // Internal QML-only signals
    void internalResponse(QString text);
    void internalError(QString msg);
    void internalTokens(int in, int out);

    // Property notifiers
    void systemPromptChanged();
    void modelChanged();
    void maxTokensChanged();
    void isLoadingChanged();
    void lastResponseChanged();

private:
    void setIsLoading(bool loading);
    void setLastResponse(const QString& response);

    QNetworkAccessManager* m_manager;
    QNetworkReply*          m_currentReply;
    QString                 m_systemPrompt;
    QString                 m_model;
    int                     m_maxTokens;
    bool                    m_isLoading;
    QString                 m_lastResponse;
    QString                 m_apiKey;
};

#endif // AIQUERYNODE_H
