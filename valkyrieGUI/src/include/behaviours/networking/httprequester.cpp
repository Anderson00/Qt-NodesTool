#include "httprequester.h"
#include "behaviours/behaviourregistry.h"

#include <QJsonDocument>
#include <QByteArray>
#include <QTimer>
#include <QPointer>

REGISTER_BEHAVIOUR(HttpRequester, "HTTP Requester", "REST client: GET/POST/PUT/DELETE with custom headers", "networking", 6, 3)

HttpRequester::HttpRequester(QObject *parent)
    : Behaviours(parent)
    , m_manager(new QNetworkAccessManager(this))
    , m_reply(nullptr)
    , m_isLoading(false)
    , m_lastStatus(0)
    , m_timeout(30000)
{
    this->setWidth(380);
    this->setHeight(320);
    this->setContentHeight(320);
    this->setQmlBodyUrl("qrc:/behaviours/networking/HttpRequester.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalResponse(QString)",
        "internalError(QString)",
        "internalStatus(int)"
    }));
}

void HttpRequester::onPinsReady()
{
    // inputs
    setPinTypeForSignature("get(QString)",             Connections::StringType);
    setPinTypeForSignature("post(QString,QString)",    Connections::AnyType);
    setPinTypeForSignature("put(QString,QString)",     Connections::AnyType);
    setPinTypeForSignature("del(QString)",             Connections::StringType);
    setPinTypeForSignature("setHeader(QString,QString)", Connections::AnyType);
    setPinTypeForSignature("cancel()",                 Connections::FlowType);
    // outputs
    setPinTypeForSignature("responseReceived(QString)", Connections::StringType);
    setPinTypeForSignature("errorOccurred(QString)",    Connections::StringType);
    setPinTypeForSignature("statusCode(int)",           Connections::IntType);
}

QMap<QString, QVariant> HttpRequester::loadInfos()
{
    return HttpRequester::static_infos();
}

QMap<QString, QVariant> HttpRequester::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "HttpRequester"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "HttpRequester"},
        {"desc",          "REST client: GET/POST/PUT/DELETE with custom headers"},
        {"inputs_count",  "6"},
        {"outputs_count", "3"}
    });
}

bool HttpRequester::isLoading() const  { return m_isLoading; }
int  HttpRequester::lastStatus() const { return m_lastStatus; }
int  HttpRequester::timeout() const    { return m_timeout; }

void HttpRequester::setTimeout(int ms)
{
    if (m_timeout != ms) {
        m_timeout = ms;
        emit timeoutChanged();
    }
}

void HttpRequester::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void HttpRequester::setLastStatus(int status)
{
    if (m_lastStatus != status) {
        m_lastStatus = status;
        emit lastStatusChanged();
    }
}

void HttpRequester::get(QString url)
{
    m_lastUrl = url;
    sendRequest("GET", url);
}

void HttpRequester::post(QString url, QString body)
{
    m_lastUrl = url;
    sendRequest("POST", url, body);
}

void HttpRequester::put(QString url, QString body)
{
    m_lastUrl = url;
    sendRequest("PUT", url, body);
}

void HttpRequester::del(QString url)
{
    m_lastUrl = url;
    sendRequest("DELETE", url);
}

void HttpRequester::setHeader(QString key, QString value)
{
    m_headers[key] = value;
}

void HttpRequester::cancel()
{
    if (m_reply && m_reply->isRunning()) {
        m_reply->abort();
    }
}

void HttpRequester::sendRequest(const QString& method, const QString& url, const QString& body)
{
    // Abort any in-flight request
    if (m_reply && m_reply->isRunning()) {
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    QUrl qurl(url);

    // SSRF guard: only allow http/https schemes
    const QString scheme = qurl.scheme().toLower();
    if (scheme != QStringLiteral("http") && scheme != QStringLiteral("https")) {
        emit errorOccurred(QStringLiteral("Blocked: only http/https URLs are allowed (got '%1')").arg(scheme));
        emit internalError(QStringLiteral("Blocked: only http/https URLs are allowed"));
        return;
    }

    QNetworkRequest request(qurl);

    // Apply custom headers
    for (auto it = m_headers.constBegin(); it != m_headers.constEnd(); ++it) {
        request.setRawHeader(it.key().toUtf8(), it.value().toUtf8());
    }

    // Default content-type for body methods
    if ((method == "POST" || method == "PUT") && !request.hasRawHeader("Content-Type")) {
        request.setRawHeader("Content-Type", "application/json");
    }

    QByteArray bodyData = body.toUtf8();

    if (method == "GET") {
        m_reply = m_manager->get(request);
    } else if (method == "POST") {
        m_reply = m_manager->post(request, bodyData);
    } else if (method == "PUT") {
        m_reply = m_manager->put(request, bodyData);
    } else if (method == "DELETE") {
        m_reply = m_manager->deleteResource(request);
    } else {
        return;
    }

    setIsLoading(true);

    // Capture the reply locally so timeout/finished lambdas always operate on
    // the exact reply they were created for — not on a potentially newer m_reply
    // assigned by a subsequent sendRequest() call.
    QPointer<QNetworkReply> capturedReply = m_reply;

    // Timeout timer — parented to the reply so it auto-deletes with it
    QTimer* timer = new QTimer(m_reply);
    timer->setSingleShot(true);
    timer->setInterval(m_timeout);
    connect(timer, &QTimer::timeout, this, [this, capturedReply]() {
        if (capturedReply && capturedReply->isRunning())
            capturedReply->abort();
    });
    timer->start();

    connect(m_reply, &QNetworkReply::finished, this, [this, capturedReply]() {
        if (!capturedReply) return;

        int code = capturedReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        setLastStatus(code);

        if (capturedReply->error() == QNetworkReply::NoError) {
            QString responseBody = QString::fromUtf8(capturedReply->readAll());
            emit responseReceived(responseBody);
            emit internalResponse(responseBody);
        } else if (capturedReply->error() != QNetworkReply::OperationCanceledError) {
            QString errMsg = capturedReply->errorString();
            emit errorOccurred(errMsg);
            emit internalError(errMsg);
        }

        emit statusCode(code);
        emit internalStatus(code);

        setIsLoading(false);

        // Clear m_reply only if it still points to this reply
        if (m_reply == capturedReply)
            m_reply = nullptr;
        capturedReply->deleteLater();
    });
}

QJsonObject HttpRequester::saveState() const
{
    QJsonObject state;
    state["lastUrl"] = m_lastUrl;
    state["timeout"] = m_timeout;

    QJsonObject headers;
    for (auto it = m_headers.constBegin(); it != m_headers.constEnd(); ++it) {
        headers[it.key()] = it.value();
    }
    state["headers"] = headers;

    return state;
}

void HttpRequester::loadState(const QJsonObject& state)
{
    if (state.contains("lastUrl"))
        m_lastUrl = state["lastUrl"].toString();
    if (state.contains("timeout"))
        setTimeout(state["timeout"].toInt(30000));
    if (state.contains("headers")) {
        QJsonObject headers = state["headers"].toObject();
        for (auto it = headers.constBegin(); it != headers.constEnd(); ++it) {
            m_headers[it.key()] = it.value().toString();
        }
    }
}
