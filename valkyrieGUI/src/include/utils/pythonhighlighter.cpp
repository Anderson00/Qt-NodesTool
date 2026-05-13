#include "pythonhighlighter.h"

#include <QQuickTextDocument>
#include <QTextDocument>
#include <QTextCharFormat>
#include <QColor>
#include <QFont>

// ── VS Code Dark+ colour palette ─────────────────────────────────────────────
namespace Color {
    static const QColor Keyword    { "#569CD6" };  // blue        – def, class, if…
    static const QColor Builtin    { "#4EC9B0" };  // teal        – print, len, range…
    static const QColor Self_      { "#9CDCFE" };  // light blue  – self
    static const QColor String_    { "#CE9178" };  // orange      – "..." '...'
    static const QColor Comment    { "#6A9955" };  // green       – # …
    static const QColor Number     { "#B5CEA8" };  // pale green  – 42, 3.14
    static const QColor Decorator  { "#C586C0" };  // purple      – @decorator
    static const QColor FuncName   { "#DCDCAA" };  // yellow      – function names after def
    static const QColor ClassName  { "#4EC9B0" };  // teal        – class names after class
    static const QColor Injected   { "#F59E0B" };  // amber       – inputs, variables, output, logs
    static const QColor Operator_  { "#D4D4D4" };  // light gray  – operators
}

PythonHighlighter::PythonHighlighter(QObject* parent)
    : QSyntaxHighlighter(parent)
{
    buildRules();
}

// ── textDocument property ─────────────────────────────────────────────────────
QQuickTextDocument* PythonHighlighter::textDocument() const
{
    return m_textDocument;
}

void PythonHighlighter::setTextDocument(QQuickTextDocument* doc)
{
    if (m_textDocument == doc) return;
    m_textDocument = doc;
    // Attach this highlighter to the QTextDocument that backs the QML TextEdit
    setDocument(doc ? doc->textDocument() : nullptr);
    emit textDocumentChanged();
}

// ── Rule builder ──────────────────────────────────────────────────────────────
void PythonHighlighter::buildRules()
{
    // ── Helper lambda ──────────────────────────────────────────────────────
    auto addRule = [this](const QString& pattern, const QColor& color,
                          bool bold = false, bool italic = false) {
        QTextCharFormat fmt;
        fmt.setForeground(color);
        if (bold)   fmt.setFontWeight(QFont::Bold);
        if (italic) fmt.setFontItalic(true);
        m_rules.append({ QRegularExpression(pattern), fmt });
    };

    // ── 1. Injected variables (highest priority — checked first) ───────────
    // These are the names the PythonEngine injects into every script namespace.
    addRule(R"(\b(inputs|variables|output|logs)\b)", Color::Injected, true);

    // ── 2. Keywords ───────────────────────────────────────────────────────
    addRule(
        R"(\b(False|None|True|and|as|assert|async|await|break|class|continue|)"
        R"(def|del|elif|else|except|finally|for|from|global|if|import|in|is|)"
        R"(lambda|nonlocal|not|or|pass|raise|return|try|while|with|yield)\b)",
        Color::Keyword);

    // ── 3. Built-in functions ─────────────────────────────────────────────
    addRule(
        R"(\b(abs|all|any|bin|bool|bytes|callable|chr|compile|complex|delattr|)"
        R"(dict|dir|divmod|enumerate|eval|exec|filter|float|format|frozenset|)"
        R"(getattr|globals|hasattr|hash|help|hex|id|input|int|isinstance|)"
        R"(issubclass|iter|len|list|locals|map|max|memoryview|min|next|object|)"
        R"(oct|open|ord|pow|print|property|range|repr|reversed|round|set|setattr|)"
        R"(slice|sorted|staticmethod|str|sum|super|tuple|type|vars|zip)\b)",
        Color::Builtin);

    // ── 4. self / cls ─────────────────────────────────────────────────────
    addRule(R"(\b(self|cls)\b)", Color::Self_);

    // ── 5. Decorators  @name ──────────────────────────────────────────────
    addRule(R"(@\w+)", Color::Decorator);

    // ── 6. Function name after 'def' ──────────────────────────────────────
    addRule(R"(\bdef\s+(\w+))", Color::FuncName);  // group 0 captures whole match

    // ── 7. Class name after 'class' ───────────────────────────────────────
    addRule(R"(\bclass\s+(\w+))", Color::ClassName);

    // ── 8. Numbers (int, float, hex, binary) ──────────────────────────────
    addRule(R"(\b(0[xX][0-9a-fA-F]+|0[bB][01]+|\d+\.?\d*([eE][+-]?\d+)?)\b)",
            Color::Number);

    // ── 9. Single-line strings  "…"  '…' (not triple — those are multiline) ─
    //     Supports escape sequences inside strings.
    addRule(R"("(?:[^"\\]|\\.)*")", Color::String_);
    addRule(R"('(?:[^'\\]|\\.)*')", Color::String_);

    // ── 10. Single-line comment  # … ──────────────────────────────────────
    {
        QTextCharFormat fmt;
        fmt.setForeground(Color::Comment);
        fmt.setFontItalic(true);
        m_rules.append({ QRegularExpression(R"(#[^\n]*)"), fmt });
    }

    // ── Triple-quote formats (used by highlightBlock for multiline state) ──
    m_tripleDoubleFormat.setForeground(Color::String_);
    m_tripleSingleFormat.setForeground(Color::String_);

    // ── Triple-quote delimiters ────────────────────────────────────────────
    m_tripleDoubleStart = QRegularExpression(R"(""")");
    m_tripleDoubleEnd   = QRegularExpression(R"(""")");
    m_tripleSingleStart = QRegularExpression(R"(''')");
    m_tripleSingleEnd   = QRegularExpression(R"(''')");
}

// ── highlightBlock ────────────────────────────────────────────────────────────
//
// Called by Qt for every text block (line) that needs re-highlighting.
// Block states:
//   0 = normal
//   1 = inside """..."""
//   2 = inside '''...'''
// ─────────────────────────────────────────────────────────────────────────────
void PythonHighlighter::highlightBlock(const QString& text)
{
    // ── A. Continue multi-line string from previous block ──────────────────
    int prevState = previousBlockState();

    if (prevState == 1) {
        // Still inside """ ... """
        auto match = m_tripleDoubleEnd.match(text);
        if (match.hasMatch()) {
            int end = match.capturedStart() + 3;
            setFormat(0, end, m_tripleDoubleFormat);
            setCurrentBlockState(0);
            // Continue normal highlighting from `end`
            // (fall through to single-line rules below, but offset)
            // We re-run the standard rules on the remainder via a local scan
            const QString rest = text.mid(end);
            for (const Rule& rule : std::as_const(m_rules)) {
                auto it = rule.pattern.globalMatch(rest);
                while (it.hasNext()) {
                    auto m = it.next();
                    setFormat(end + m.capturedStart(), m.capturedLength(), rule.format);
                }
            }
            return;
        } else {
            setFormat(0, text.length(), m_tripleDoubleFormat);
            setCurrentBlockState(1);
            return;
        }
    }

    if (prevState == 2) {
        // Still inside ''' ... '''
        auto match = m_tripleSingleEnd.match(text);
        if (match.hasMatch()) {
            int end = match.capturedStart() + 3;
            setFormat(0, end, m_tripleSingleFormat);
            setCurrentBlockState(0);
            const QString rest = text.mid(end);
            for (const Rule& rule : std::as_const(m_rules)) {
                auto it = rule.pattern.globalMatch(rest);
                while (it.hasNext()) {
                    auto m = it.next();
                    setFormat(end + m.capturedStart(), m.capturedLength(), rule.format);
                }
            }
            return;
        } else {
            setFormat(0, text.length(), m_tripleSingleFormat);
            setCurrentBlockState(2);
            return;
        }
    }

    // ── B. Normal line: apply single-line rules first ─────────────────────
    setCurrentBlockState(0);

    for (const Rule& rule : std::as_const(m_rules)) {
        auto it = rule.pattern.globalMatch(text);
        while (it.hasNext()) {
            auto m = it.next();
            setFormat(m.capturedStart(), m.capturedLength(), rule.format);
        }
    }

    // ── C. Scan for triple-quote openers on this line ─────────────────────
    // Check """ first, then '''
    // If we find an opener without a closer on the same line → set block state

    int idx = 0;
    while (idx < text.length()) {
        // Try """
        auto dblMatch = m_tripleDoubleStart.match(text, idx);
        // Try '''
        auto sglMatch = m_tripleSingleStart.match(text, idx);

        bool hasDbl = dblMatch.hasMatch();
        bool hasSgl = sglMatch.hasMatch();

        if (!hasDbl && !hasSgl) break;

        // Pick the one that appears first
        bool useDbl = hasDbl && (!hasSgl || dblMatch.capturedStart() <= sglMatch.capturedStart());

        int start    = useDbl ? dblMatch.capturedStart() : sglMatch.capturedStart();
        auto& endRx  = useDbl ? m_tripleDoubleEnd : m_tripleSingleEnd;
        auto& fmt    = useDbl ? m_tripleDoubleFormat : m_tripleSingleFormat;
        int   state  = useDbl ? 1 : 2;

        // Look for the closing delimiter after the opener
        auto closeMatch = endRx.match(text, start + 3);
        if (closeMatch.hasMatch()) {
            int end = closeMatch.capturedStart() + 3;
            setFormat(start, end - start, fmt);
            idx = end;
        } else {
            // No closing delimiter on this line → block state
            setFormat(start, text.length() - start, fmt);
            setCurrentBlockState(state);
            break;
        }
    }
}
