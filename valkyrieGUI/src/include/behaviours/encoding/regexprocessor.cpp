#include "regexprocessor.h"
#include "behaviours/behaviourregistry.h"

REGISTER_BEHAVIOUR(RegexProcessor, "Regex Processor", "Match, capture groups, and replace with regular expressions", "encoding", 3, 3)

RegexProcessor::RegexProcessor(QObject *parent)
    : Behaviours(parent)
    , m_caseInsensitive(false)
    , m_multiLine(false)
    , m_matchCount(0)
{
    this->setWidth(340);
    this->setHeight(300);
    this->setContentHeight(300);
    this->setQmlBodyUrl("qrc:/behaviours/encoding/RegexProcessor.qml");
    this->addInputOutputExclusion(QList<QString>({
        "internalMatch(QStringList,int)",
        "internalNoMatch()",
        "internalReplaced(QString)",
        "internalPatternError(QString)"
    }));
}

void RegexProcessor::onPinsReady()
{
    // inputs
    setPinTypeForSignature("setText(QString)",           Connections::StringType);
    setPinTypeForSignature("setPattern(QString)",        Connections::StringType);
    setPinTypeForSignature("replace(QString)",           Connections::StringType);
    // outputs
    setPinTypeForSignature("matchFound(QStringList)", Connections::ArrayType);
    setPinTypeForSignature("noMatch()",               Connections::FlowType);
    setPinTypeForSignature("replaced(QString)",       Connections::StringType);
}

QMap<QString, QVariant> RegexProcessor::loadInfos()
{
    return RegexProcessor::static_infos();
}

QMap<QString, QVariant> RegexProcessor::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "RegexProcessor"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "RegexProcessor"},
        {"desc",          "Match, capture groups, and replace with regular expressions"},
        {"inputs_count",  "3"},
        {"outputs_count", "3"}
    });
}

void RegexProcessor::setMatchCount(int count)
{
    if (m_matchCount != count) {
        m_matchCount = count;
        emit matchCountChanged();
    }
}

void RegexProcessor::setLastError(const QString& err)
{
    if (m_lastError != err) {
        m_lastError = err;
        emit lastErrorChanged();
    }
}

void RegexProcessor::rebuildRegex()
{
    QRegularExpression::PatternOptions opts = QRegularExpression::NoPatternOption;
    if (m_caseInsensitive)
        opts |= QRegularExpression::CaseInsensitiveOption;
    if (m_multiLine)
        opts |= QRegularExpression::MultilineOption;

    m_regex.setPattern(m_pattern);
    m_regex.setPatternOptions(opts);

    if (!m_regex.isValid()) {
        setLastError(m_regex.errorString());
        emit internalPatternError(m_regex.errorString());
    } else {
        setLastError(QString());
    }
}

void RegexProcessor::setPattern(QString pattern)
{
    if (m_pattern != pattern) {
        m_pattern = pattern;
        rebuildRegex();
        emit patternChanged();
    }
}

void RegexProcessor::setCaseInsensitive(bool ci)
{
    if (m_caseInsensitive != ci) {
        m_caseInsensitive = ci;
        rebuildRegex();
        emit caseInsensitiveChanged();
    }
}

void RegexProcessor::setMultiLine(bool ml)
{
    if (m_multiLine != ml) {
        m_multiLine = ml;
        rebuildRegex();
        emit multiLineChanged();
    }
}

void RegexProcessor::setText(QString text)
{
    m_currentText = text;

    if (!m_regex.isValid() || m_pattern.isEmpty()) {
        setMatchCount(0);
        emit noMatch();
        emit internalNoMatch();
        return;
    }

    // Count all matches
    int count = 0;
    QRegularExpressionMatchIterator it = m_regex.globalMatch(text);
    while (it.hasNext()) {
        it.next();
        ++count;
    }
    setMatchCount(count);

    // Get first match and its capture groups
    QRegularExpressionMatch firstMatch = m_regex.match(text);
    if (firstMatch.hasMatch()) {
        QStringList groups;
        for (int i = 0; i <= firstMatch.lastCapturedIndex(); ++i) {
            groups << firstMatch.captured(i);
        }
        emit matchFound(groups);
        emit internalMatch(groups, count);
    } else {
        setMatchCount(0);
        emit noMatch();
        emit internalNoMatch();
    }
}

void RegexProcessor::replace(QString replacement)
{
    if (!m_regex.isValid() || m_currentText.isEmpty()) return;

    QString result = m_currentText;
    result.replace(m_regex, replacement);
    emit replaced(result);
    emit internalReplaced(result);
}

QJsonObject RegexProcessor::saveState() const
{
    QJsonObject state;
    state["pattern"]         = m_pattern;
    state["caseInsensitive"] = m_caseInsensitive;
    state["multiLine"]       = m_multiLine;
    return state;
}

void RegexProcessor::loadState(const QJsonObject& state)
{
    if (state.contains("caseInsensitive"))
        setCaseInsensitive(state["caseInsensitive"].toBool(false));
    if (state.contains("multiLine"))
        setMultiLine(state["multiLine"].toBool(false));
    if (state.contains("pattern"))
        setPattern(state["pattern"].toString());
}
