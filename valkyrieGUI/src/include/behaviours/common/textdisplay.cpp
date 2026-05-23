#include "textdisplay.h"
#include "behaviours/behaviourregistry.h"
#include <QVariantList>

REGISTER_BEHAVIOUR(TextDisplay, "Text Display", "Console/log viewer — receives and displays text lines", "Visualization", 3, 0)

TextDisplay::TextDisplay(QObject *parent) : Behaviours(parent)
{
    this->setWidth(300);
    this->setHeight(250);
    this->setContentHeight(250);
    this->setQmlBodyUrl("qrc:/behaviours/common/TextDisplay.qml");
    this->addInputOutputExclusion(QList<QString>({
        "displayTextChanged()",
        "lineCountChanged()",
        "maxLinesChanged()"
    }));
}

QMap<QString, QVariant> TextDisplay::loadInfos()
{
    return TextDisplay::static_infos();
}

QMap<QString, QVariant> TextDisplay::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "TextDisplay"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "TextDisplay"},
        {"desc",          "Console/log viewer — receives and displays text lines"},
        {"inputs_count",  "3"},
        {"outputs_count", "0"}
    });
}

// ── Accessors ────────────────────────────────────────────────────────────────

QString TextDisplay::displayText() const { return m_lines.join("\n"); }
int     TextDisplay::lineCount()   const { return m_lines.size(); }
int     TextDisplay::maxLines()    const { return m_maxLines; }

// ── Slots ────────────────────────────────────────────────────────────────────

void TextDisplay::appendText(QString text) {
    if (m_lines.isEmpty())
        m_lines.append(text);
    else
        m_lines.last().append(text);
    trimLines();
    emit displayTextChanged();
    emit lineCountChanged();
}

void TextDisplay::appendLine(QString line) {
    m_lines.append(line);
    trimLines();
    emit displayTextChanged();
    emit lineCountChanged();
}

void TextDisplay::clear() {
    m_lines.clear();
    emit displayTextChanged();
    emit lineCountChanged();
}

void TextDisplay::setMaxLines(int max) {
    max = qMax(1, max);
    if (m_maxLines != max) {
        m_maxLines = max;
        trimLines();
        emit maxLinesChanged();
        emit displayTextChanged();
        emit lineCountChanged();
    }
}

void TextDisplay::setInputData(const QVariantList& data)
{
    QStringList parts;
    for (const QVariant& v : data)
        parts << v.toString();
    appendLine(parts.join(", "));
}

void TextDisplay::trimLines() {
    while (m_lines.size() > m_maxLines)
        m_lines.removeFirst();
}

// ── State persistence ────────────────────────────────────────────────────────

QJsonObject TextDisplay::saveState() const {
    return { {"maxLines", m_maxLines} };
}

void TextDisplay::loadState(const QJsonObject& state) {
    if (state.contains("maxLines"))
        setMaxLines(state["maxLines"].toInt(500));
}
