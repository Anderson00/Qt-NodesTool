#pragma once

#include <QSyntaxHighlighter>
#include <QTextCharFormat>
#include <QRegularExpression>
#include <QList>
#include <QObject>
#include <QQuickTextDocument>

// ─────────────────────────────────────────────────────────────────────────────
// PythonHighlighter
//
// QSyntaxHighlighter for Python code. Designed to be attached to a QML
// TextEdit via its `textDocument` property (QQuickTextDocument).
//
// Usage in QML:
//   PythonHighlighter {
//       id: highlighter
//       textDocument: codeTextEdit.textDocument
//   }
//
// Colour palette: VS Code Dark+ (Python theme)
// Block states:
//   0 = normal
//   1 = inside triple-double-quoted string  """..."""
//   2 = inside triple-single-quoted string  '''...'''
// ─────────────────────────────────────────────────────────────────────────────
class PythonHighlighter : public QSyntaxHighlighter
{
    Q_OBJECT

    Q_PROPERTY(QQuickTextDocument* textDocument
               READ textDocument
               WRITE setTextDocument
               NOTIFY textDocumentChanged)

public:
    explicit PythonHighlighter(QObject* parent = nullptr);

    QQuickTextDocument* textDocument() const;
    void setTextDocument(QQuickTextDocument* doc);

signals:
    void textDocumentChanged();

protected:
    void highlightBlock(const QString& text) override;

private:
    // ── Single-line rule ─────────────────────────────────────────────────────
    struct Rule {
        QRegularExpression pattern;
        QTextCharFormat    format;
    };
    QList<Rule> m_rules;

    // ── Multi-line triple-quote string formats ───────────────────────────────
    QTextCharFormat m_tripleDoubleFormat; // """..."""
    QTextCharFormat m_tripleSingleFormat; // '''...'''

    // ── Delimiters (pre-compiled) ────────────────────────────────────────────
    QRegularExpression m_tripleDoubleStart;
    QRegularExpression m_tripleDoubleEnd;
    QRegularExpression m_tripleSingleStart;
    QRegularExpression m_tripleSingleEnd;

    // ── Helpers ──────────────────────────────────────────────────────────────
    void buildRules();

    // Handle one triple-quote block inside highlightBlock.
    // Returns true if the rest of the line is consumed by the block.
    bool handleTripleQuote(const QString& text,
                           int startIndex,
                           const QRegularExpression& endDelim,
                           const QTextCharFormat& fmt,
                           int blockState);

    QQuickTextDocument* m_textDocument = nullptr;
};
