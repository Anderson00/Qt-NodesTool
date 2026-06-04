#ifndef DATATABLEVIEWER_H
#define DATATABLEVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QStringList>
#include <QVariantList>
#include <QList>
#include <behaviours/behaviours.h>

class DataTableViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int     rowCount    READ rowCount    NOTIFY tableChanged)
    Q_PROPERTY(int     columnCount READ columnCount NOTIFY tableChanged)
    Q_PROPERTY(QString filterText  READ filterText  WRITE setFilterText NOTIFY filterTextChanged)

public:
    explicit DataTableViewer(QObject *parent = nullptr);

    void onPinsReady() override;

    virtual QMap<QString, QVariant> loadInfos() override;
    static  QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int     rowCount()    const;
    int     columnCount() const;
    QString filterText()  const;
    void    setFilterText(const QString& text);

public slots:
    void addRow(QVariantList row);
    void setHeaders(QStringList headers);
    void clear();
    void removeRow(int index);

signals:
    // Node outputs
    void rowClicked(int row, QVariantList data);
    void cellClicked(int row, int col, QString value);

    // Internal QML-only signals
    void internalAddRow(QVariantList row);
    void internalSetHeaders(QStringList headers);
    void internalClear();
    void internalRemoveRow(int index);

    // Property notifiers
    void tableChanged();
    void filterTextChanged();

private:
    QList<QVariantList> m_rows;
    QStringList         m_headers;
    QString             m_filterText;
};

#endif // DATATABLEVIEWER_H
