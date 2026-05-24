#include "jsontreeviewer.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(JsonTreeViewer, "JSON Tree Viewer", "Display JSON as an interactive collapsible tree", "data", 3, 0)

JsonTreeViewer::JsonTreeViewer(QObject *parent)
    : Behaviours(parent)
    , m_nodeCount(0)
    , m_expandDepth(2)
{
    this->setWidth(320);
    this->setHeight(320);
    this->setContentHeight(320);
    this->setQmlBodyUrl("qrc:/behaviours/data/JsonTreeViewer.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalLoad(QVariantList)",
        "internalClear()"
    }));
}

QMap<QString, QVariant> JsonTreeViewer::loadInfos()
{
    return JsonTreeViewer::static_infos();
}

QMap<QString, QVariant> JsonTreeViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "JsonTreeViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "JsonTreeViewer"},
        {"desc",          "Display JSON as an interactive collapsible tree"},
        {"inputs_count",  "3"},
        {"outputs_count", "0"}
    });
}

int JsonTreeViewer::nodeCount()   const { return m_nodeCount;   }
int JsonTreeViewer::expandDepth() const { return m_expandDepth; }

void JsonTreeViewer::loadJson(QString json)
{
    m_lastJson = json;

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8(), &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        // Emit a single error node
        QVariantMap errorNode;
        errorNode["key"]         = "error";
        errorNode["value"]       = parseError.errorString();
        errorNode["type"]        = "string";
        errorNode["depth"]       = 0;
        errorNode["hasChildren"] = false;
        errorNode["expanded"]    = false;
        QVariantList model;
        model.append(errorNode);
        m_nodeCount = 1;
        emit nodeCountChanged();
        emit internalLoad(model);
        return;
    }

    QVariantList model = buildFlatModel(doc);
    m_nodeCount = model.size();
    emit nodeCountChanged();
    emit internalLoad(model);
}

void JsonTreeViewer::clear()
{
    m_lastJson.clear();
    m_nodeCount = 0;
    emit nodeCountChanged();
    emit internalClear();
}

void JsonTreeViewer::setExpandDepth(int depth)
{
    if (m_expandDepth != depth) {
        m_expandDepth = depth;
        emit expandDepthChanged();
    }
    // Re-flatten with new expand depth if we have data
    if (!m_lastJson.isEmpty()) {
        QJsonParseError parseError;
        QJsonDocument doc = QJsonDocument::fromJson(m_lastJson.toUtf8(), &parseError);
        if (parseError.error == QJsonParseError::NoError) {
            QVariantList model = buildFlatModel(doc);
            m_nodeCount = model.size();
            emit nodeCountChanged();
            emit internalLoad(model);
        }
    }
}

void JsonTreeViewer::flattenValue(const QString& key, const QJsonValue& val,
                                   int depth, QVariantList& out) const
{
    QVariantMap node;
    node["key"]   = key;
    node["depth"] = depth;

    bool expanded = (m_expandDepth < 0 || depth < m_expandDepth);

    if (val.isObject()) {
        QJsonObject obj = val.toObject();
        node["value"]       = QString("{%1}").arg(obj.size());
        node["type"]        = "object";
        node["hasChildren"] = !obj.isEmpty();
        node["expanded"]    = expanded && !obj.isEmpty();
        out.append(node);

        if (expanded) {
            for (auto it = obj.constBegin(); it != obj.constEnd(); ++it)
                flattenValue(it.key(), it.value(), depth + 1, out);
        }
    } else if (val.isArray()) {
        QJsonArray arr = val.toArray();
        node["value"]       = QString("[%1]").arg(arr.size());
        node["type"]        = "array";
        node["hasChildren"] = !arr.isEmpty();
        node["expanded"]    = expanded && !arr.isEmpty();
        out.append(node);

        if (expanded) {
            for (int i = 0; i < arr.size(); ++i)
                flattenValue(QString::number(i), arr[i], depth + 1, out);
        }
    } else if (val.isString()) {
        node["value"]       = val.toString();
        node["type"]        = "string";
        node["hasChildren"] = false;
        node["expanded"]    = false;
        out.append(node);
    } else if (val.isBool()) {
        node["value"]       = val.toBool() ? "true" : "false";
        node["type"]        = "bool";
        node["hasChildren"] = false;
        node["expanded"]    = false;
        out.append(node);
    } else if (val.isNull()) {
        node["value"]       = "null";
        node["type"]        = "null";
        node["hasChildren"] = false;
        node["expanded"]    = false;
        out.append(node);
    } else {
        // number
        node["value"]       = QString::number(val.toDouble());
        node["type"]        = "number";
        node["hasChildren"] = false;
        node["expanded"]    = false;
        out.append(node);
    }
}

QVariantList JsonTreeViewer::buildFlatModel(const QJsonDocument& doc) const
{
    QVariantList model;
    if (doc.isObject()) {
        QJsonObject obj = doc.object();
        for (auto it = obj.constBegin(); it != obj.constEnd(); ++it)
            flattenValue(it.key(), it.value(), 0, model);
    } else if (doc.isArray()) {
        QJsonArray arr = doc.array();
        for (int i = 0; i < arr.size(); ++i)
            flattenValue(QString::number(i), arr[i], 0, model);
    }
    return model;
}

QJsonObject JsonTreeViewer::saveState() const
{
    QJsonObject state;
    state["expandDepth"] = m_expandDepth;
    state["lastJson"]    = m_lastJson;
    return state;
}

void JsonTreeViewer::loadState(const QJsonObject& state)
{
    if (state.contains("expandDepth"))
        m_expandDepth = state["expandDepth"].toInt(2);
    if (state.contains("lastJson") && !state["lastJson"].toString().isEmpty())
        loadJson(state["lastJson"].toString());
}
