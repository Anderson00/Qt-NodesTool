#ifndef MAPVIEWER_H
#define MAPVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QVector>
#include <QPointF>
#include <behaviours/behaviours.h>

struct MapMarker {
    double lat;
    double lng;
    QString label;
};

class MapViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int     markerCount  READ markerCount  NOTIFY markerCountChanged)
    Q_PROPERTY(int     traceLength  READ traceLength  NOTIFY traceLengthChanged)
    Q_PROPERTY(double  centerLat    READ centerLat    NOTIFY centerChanged)
    Q_PROPERTY(double  centerLng    READ centerLng    NOTIFY centerChanged)
    Q_PROPERTY(int     zoom         READ zoom         NOTIFY zoomChanged)

public:
    explicit MapViewer(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int    markerCount() const { return m_markers.size(); }
    int    traceLength() const { return m_trace.size(); }
    double centerLat()   const { return m_centerLat; }
    double centerLng()   const { return m_centerLng; }
    int    zoom()        const { return m_zoom; }

    Q_INVOKABLE QVariantList getMarkers() const;
    Q_INVOKABLE QVariantList getTrace()   const;

public slots:
    void addMarker(double lat, double lng, QString label);
    void addTracePoint(double lat, double lng);
    void setCenter(double lat, double lng, int zoom);
    void clearMarkers();
    void clearTrace();
    void clearAll();
    void setStartPoint(double lat, double lng);
    void setEndPoint(double lat, double lng);
    void removeMarkerAt(int index);
    void updateMarkerLabel(int index, QString label);

signals:
    // node outputs
    void markerClicked(double lat, double lng, QString label);
    void mapClicked(double lat, double lng);

    // QML bridge
    void internalMarkersChanged();
    void internalTraceChanged();
    void internalCenterChanged(double lat, double lng, int zoom);
    void internalClear();

    // property notifiers
    void markerCountChanged();
    void traceLengthChanged();
    void centerChanged();
    void zoomChanged();

private:
    QVector<MapMarker> m_markers;
    QVector<QPointF>   m_trace;
    MapMarker          m_startPoint{0,0,""};
    MapMarker          m_endPoint{0,0,""};
    bool               m_hasStart = false;
    bool               m_hasEnd   = false;

    double m_centerLat = 48.8566;
    double m_centerLng = 2.3522;
    int    m_zoom      = 13;
};

#endif // MAPVIEWER_H
