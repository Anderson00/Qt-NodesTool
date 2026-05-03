#ifndef SUBTHEME_H
#define SUBTHEME_H

#include "abstracttheme.h"

class SubTheme : public AbstractTheme {
    Q_OBJECT
    Q_PROPERTY(QString name READ name CONSTANT)

public:
    SubTheme(const QString& name, QObject* parent = nullptr);

    QString name() const;
    void copyFromGlobal(const AbstractTheme* source);

private:
    QString m_name;
};
#endif // SUBTHEME_H
