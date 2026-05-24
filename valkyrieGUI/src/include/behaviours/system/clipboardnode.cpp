#include "clipboardnode.h"
#include "behaviours/behaviourregistry.h"

#include <QGuiApplication>

REGISTER_BEHAVIOUR(ClipboardNode, "Clipboard", "Read and write system clipboard text", "system", 2, 1)

ClipboardNode::ClipboardNode(QObject *parent) : Behaviours(parent)
{
    setWidth(280);
    setHeight(200);
    setContentHeight(200);
    setQmlBodyUrl("qrc:/behaviours/system/ClipboardNode.qml");
    addInputOutputExclusion(QList<QString>({
        "internalClipboardChanged(QString)",
        "internalRead(QString)",
        "lastTextChanged()",
        "monitorChangesChanged()"
    }));
}

QMap<QString, QVariant> ClipboardNode::loadInfos() { return ClipboardNode::static_infos(); }

QMap<QString, QVariant> ClipboardNode::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",           "ClipboardNode"},
        {"type",           Behaviours::Type::CPP},
        {"className",      "ClipboardNode"},
        {"desc",           "Read and write system clipboard text"},
        {"inputs_count",   "2"},
        {"outputs_count",  "1"}
    });
}

QString ClipboardNode::lastText()       const { return m_lastText; }
bool    ClipboardNode::monitorChanges() const { return m_monitorChanges; }

void ClipboardNode::setMonitorChanges(bool enabled)
{
    if (m_monitorChanges == enabled)
        return;

    m_monitorChanges = enabled;
    emit monitorChangesChanged();

    QClipboard *cb = QGuiApplication::clipboard();
    if (enabled) {
        m_clipboardConnection = connect(cb, &QClipboard::changed, this, [this](QClipboard::Mode mode) {
            if (mode == QClipboard::Clipboard) {
                QString text = QGuiApplication::clipboard()->text();
                m_lastText = text;
                emit lastTextChanged();
                emit clipboardRead(text);
                emit internalClipboardChanged(text);
            }
        });
    } else {
        disconnect(m_clipboardConnection);
    }
}

void ClipboardNode::writeText(QString text)
{
    QGuiApplication::clipboard()->setText(text);
    m_lastText = text;
    emit lastTextChanged();
}

void ClipboardNode::readText()
{
    QString text = QGuiApplication::clipboard()->text();
    m_lastText = text;
    emit lastTextChanged();
    emit clipboardRead(text);
    emit internalRead(text);
}
