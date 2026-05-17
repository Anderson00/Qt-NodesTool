#include "aiquerynode.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(AIQueryNode, "AI Query", "Send prompts to Claude API (claude-haiku-4-5-20251001) and receive responses", "ai", 4, 3)

AIQueryNode::AIQueryNode(QObject *parent)
    : Behaviours(parent)
    , m_manager(new QNetworkAccessManager(this))
    , m_currentReply(nullptr)
    , m_model("claude-haiku-4-5-20251001")
    , m_maxTokens(1024)
    , m_isLoading(false)
{
    this->setWidth(380);
    this->setHeight(360);
    this->setContentHeight(360);
    this->setQmlBodyUrl("qrc:/behaviours/ai/AIQueryNode.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalResponse(QString)",
        "internalError(QString)",
        "internalTokens(int,int)"
    }));
}

QMap<QString, QVariant> AIQueryNode::loadInfos()
{
    return AIQueryNode::static_infos();
}

QMap<QString, QVariant> AIQueryNode::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "AIQueryNode"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "AIQueryNode"},
        {"desc",          "Send prompts to Claude API (claude-haiku-4-5-20251001) and receive responses"},
        {"inputs_count",  "4"},
        {"outputs_count", "3"}
    });
}

void AIQueryNode::setSystemPrompt(const QString& sp)
{
    if (m_systemPrompt != sp) {
        m_systemPrompt = sp;
        emit systemPromptChanged();
    }
}

// Slot overload (takes QString by value for QML/signal compatibility)
void AIQueryNode::setSystemPrompt(QString sp)
{
    setSystemPrompt(static_cast<const QString&>(sp));
}

void AIQueryNode::setModel(const QString& model)
{
    if (m_model != model) {
        m_model = model;
        emit modelChanged();
    }
}

void AIQueryNode::setModel(QString model)
{
    setModel(static_cast<const QString&>(model));
}

void AIQueryNode::setMaxTokens(int tokens)
{
    if (m_maxTokens != tokens) {
        m_maxTokens = tokens;
        emit maxTokensChanged();
    }
}

void AIQueryNode::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void AIQueryNode::setLastResponse(const QString& response)
{
    if (m_lastResponse != response) {
        m_lastResponse = response;
        emit lastResponseChanged();
    }
}

void AIQueryNode::setApiKey(QString key)
{
    m_apiKey = key;
}

void AIQueryNode::cancel()
{
    if (m_currentReply && m_currentReply->isRunning()) {
        m_currentReply->abort();
    }
}

void AIQueryNode::query(QString userPrompt)
{
    if (m_apiKey.isEmpty()) {
        emit error("API key not set");
        emit internalError("API key not set");
        return;
    }

    // Abort any in-flight request
    if (m_currentReply && m_currentReply->isRunning()) {
        m_currentReply->abort();
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    }

    // Build request body
    QJsonObject body;
    body["model"]      = m_model;
    body["max_tokens"] = m_maxTokens;
    if (!m_systemPrompt.isEmpty())
        body["system"] = m_systemPrompt;

    QJsonArray messages;
    QJsonObject userMsg;
    userMsg["role"]    = "user";
    userMsg["content"] = userPrompt;
    messages.append(userMsg);
    body["messages"]   = messages;

    QByteArray bodyData = QJsonDocument(body).toJson(QJsonDocument::Compact);

    QNetworkRequest request(QUrl("https://api.anthropic.com/v1/messages"));
    request.setRawHeader("x-api-key",          m_apiKey.toUtf8());
    request.setRawHeader("anthropic-version",  "2023-06-01");
    request.setRawHeader("content-type",       "application/json");

    setIsLoading(true);
    m_currentReply = m_manager->post(request, bodyData);

    connect(m_currentReply, &QNetworkReply::finished, this, [this]() {
        if (!m_currentReply) return;

        if (m_currentReply->error() == QNetworkReply::NoError) {
            QByteArray responseData = m_currentReply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(responseData);
            QJsonObject obj   = doc.object();

            // Extract text from content[0].text
            QString text;
            QJsonArray contentArr = obj["content"].toArray();
            if (!contentArr.isEmpty()) {
                text = contentArr[0].toObject()["text"].toString();
            }

            // Extract token usage
            QJsonObject usage = obj["usage"].toObject();
            int inputTokens   = usage["input_tokens"].toInt();
            int outputTokens  = usage["output_tokens"].toInt();

            setLastResponse(text);
            emit responseReceived(text);
            emit internalResponse(text);
            emit tokensUsed(inputTokens, outputTokens);
            emit internalTokens(inputTokens, outputTokens);
        } else if (m_currentReply->error() != QNetworkReply::OperationCanceledError) {
            // Try to parse error body
            QByteArray errData  = m_currentReply->readAll();
            QJsonDocument errDoc = QJsonDocument::fromJson(errData);
            QString errMsg;
            if (!errDoc.isNull() && errDoc.object().contains("error")) {
                errMsg = errDoc.object()["error"].toObject()["message"].toString();
            }
            if (errMsg.isEmpty())
                errMsg = m_currentReply->errorString();

            emit error(errMsg);
            emit internalError(errMsg);
        }

        setIsLoading(false);
        m_currentReply->deleteLater();
        m_currentReply = nullptr;
    });
}

QJsonObject AIQueryNode::saveState() const
{
    QJsonObject state;
    state["systemPrompt"] = m_systemPrompt;
    state["model"]        = m_model;
    state["maxTokens"]    = m_maxTokens;
    // NEVER save apiKey
    return state;
}

void AIQueryNode::loadState(const QJsonObject& state)
{
    if (state.contains("systemPrompt"))
        setSystemPrompt(state["systemPrompt"].toString());
    if (state.contains("model"))
        setModel(state["model"].toString());
    if (state.contains("maxTokens"))
        setMaxTokens(state["maxTokens"].toInt(1024));
}
