#ifndef REGEXPROCESSOR_H
#define REGEXPROCESSOR_H

#include <QObject>
#include <QJsonObject>
#include <QRegularExpression>
#include <QRegularExpressionMatch>
#include <behaviours/behaviours.h>

class RegexProcessor : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(QString pattern          READ pattern         WRITE setPattern         NOTIFY patternChanged)
    Q_PROPERTY(bool    caseInsensitive  READ caseInsensitive WRITE setCaseInsensitive  NOTIFY caseInsensitiveChanged)
    Q_PROPERTY(bool    multiLine        READ multiLine       WRITE setMultiLine        NOTIFY multiLineChanged)
    Q_PROPERTY(int     matchCount       READ matchCount                                NOTIFY matchCountChanged)
    Q_PROPERTY(QString lastError        READ lastError                                 NOTIFY lastErrorChanged)

public:
    explicit RegexProcessor(QObject *parent = nullptr);

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString pattern()         const { return m_pattern; }
    bool    caseInsensitive() const { return m_caseInsensitive; }
    bool    multiLine()       const { return m_multiLine; }
    int     matchCount()      const { return m_matchCount; }
    QString lastError()       const { return m_lastError; }

public slots:
    void setText(QString text);
    void setPattern(QString pattern);
    void replace(QString replacement);
    void setCaseInsensitive(bool ci);
    void setMultiLine(bool ml);

signals:
    // Node outputs
    void matchFound(QStringList captureGroups);
    void noMatch();
    void replaced(QString result);

    // Internal QML-only signals
    void internalMatch(QStringList groups, int matchCount);
    void internalNoMatch();
    void internalReplaced(QString result);
    void internalPatternError(QString error);

    // Property notifiers
    void patternChanged();
    void caseInsensitiveChanged();
    void multiLineChanged();
    void matchCountChanged();
    void lastErrorChanged();

private:
    void rebuildRegex();
    void setMatchCount(int count);
    void setLastError(const QString& err);

    QRegularExpression m_regex;
    QString            m_pattern;
    QString            m_currentText;
    bool               m_caseInsensitive;
    bool               m_multiLine;
    int                m_matchCount;
    QString            m_lastError;
};

#endif // REGEXPROCESSOR_H
