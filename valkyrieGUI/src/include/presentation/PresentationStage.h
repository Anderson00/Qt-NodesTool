#ifndef PRESENTATIONSTAGE_H
#define PRESENTATIONSTAGE_H

#include <QObject>
#include <QString>
#include <QJsonObject>

// Represents a single saved "stage" in Presentation Mode — a named camera
// framing (world-space rectangle + optional zoom) the user can navigate to
// during a presentation. Stages live inside ViewPortWindow and are
// serialized as part of the workspace JSON.
class PresentationStage : public QObject
{
    Q_OBJECT
public:
    explicit PresentationStage(QObject* parent = nullptr);

    QString id;
    QString name;
    qreal   worldX   = 0;
    qreal   worldY   = 0;
    qreal   worldW   = 800;
    qreal   worldH   = 600;
    qreal   zoom     = -1;   // -1 = auto-fit
    QString notes;

    QJsonObject toJson() const;
    static PresentationStage* fromJson(const QJsonObject& obj, QObject* parent = nullptr);
};

#endif // PRESENTATIONSTAGE_H
