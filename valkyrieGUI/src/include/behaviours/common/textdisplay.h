#ifndef TEXTDISPLAY_H
#define TEXTDISPLAY_H

#include <QObject>
#include <QJsonObject>
#include <behaviours/behaviours.h>

class TextDisplay : public Behaviours
{
    Q_OBJECT
    Q_PROPERTY(QString displayText READ displayText NOTIFY displayTextChanged)
    Q_PROPERTY(int     lineCount   READ lineCount   NOTIFY lineCountChanged)
    Q_PROPERTY(int     maxLines    READ maxLines    WRITE setMaxLines NOTIFY maxLinesChanged)

public:
    explicit TextDisplay(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    QString displayText() const;
    int     lineCount()   const;
    int     maxLines()    const;

public slots:
    void appendText(QString text);
    void appendLine(QString line);
    void clear();
    void setMaxLines(int max);

signals:
    void displayTextChanged();
    void lineCountChanged();
    void maxLinesChanged();

private:
    void trimLines();

    QStringList m_lines;
    int         m_maxLines = 500;
};

#endif // TEXTDISPLAY_H
