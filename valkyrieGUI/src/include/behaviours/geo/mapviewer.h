#ifndef MAPVIEWER_H
#define MAPVIEWER_H

#include <QObject>
#include <QJsonObject>
#include <QJsonArray>
#include <QVector>
#include <QPointF>
#include <behaviours/behaviours.h>

struct MapMarker {
    double  lat;
    double  lng;
    QString label;
    QString payload;
};

struct MapCircle {
    double  lat;
    double  lng;
    double  radiusMeters;
    QString label;
    QString color;   // hex, e.g. "#3b82f6"
};

class MapViewer : public Behaviours
{
    Q_OBJECT

    Q_PROPERTY(int     markerCount    READ markerCount    NOTIFY markerCountChanged)
    Q_PROPERTY(int     traceLength    READ traceLength    NOTIFY traceLengthChanged)
    Q_PROPERTY(double  centerLat      READ centerLat      NOTIFY centerChanged)
    Q_PROPERTY(double  centerLng      READ centerLng      NOTIFY centerChanged)
    Q_PROPERTY(int     zoom           READ zoom           NOTIFY zoomChanged)
    Q_PROPERTY(bool    hasLiveMarker  READ hasLiveMarker  NOTIFY liveMarkerChanged)
    Q_PROPERTY(double  liveLat        READ liveLat        NOTIFY liveMarkerChanged)
    Q_PROPERTY(double  liveLng        READ liveLng        NOTIFY liveMarkerChanged)
    Q_PROPERTY(int     circleCount    READ circleCount    NOTIFY circleCountChanged)
    Q_PROPERTY(bool    inGeofence     READ inGeofence     NOTIFY geofenceStateChanged)
    Q_PROPERTY(bool    hasGeofence    READ hasGeofence    NOTIFY geofenceConfigChanged)
    Q_PROPERTY(double  geofenceLat    READ geofenceLat    NOTIFY geofenceConfigChanged)
    Q_PROPERTY(double  geofenceLng    READ geofenceLng    NOTIFY geofenceConfigChanged)
    Q_PROPERTY(double  geofenceRadius READ geofenceRadius NOTIFY geofenceConfigChanged)

public:
    explicit MapViewer(QObject *parent = nullptr);

    QMap<QString, QVariant> loadInfos() override;
    static QMap<QString, QVariant> static_infos();

    QJsonObject saveState() const override;
    void loadState(const QJsonObject& state) override;

    int     markerCount()    const { return m_markers.size(); }
    int     traceLength()    const { return m_trace.size(); }
    double  centerLat()      const { return m_centerLat; }
    double  centerLng()      const { return m_centerLng; }
    int     zoom()           const { return m_zoom; }
    bool    hasLiveMarker()  const { return m_hasLive; }
    double  liveLat()        const { return m_liveMarker.lat; }
    double  liveLng()        const { return m_liveMarker.lng; }
    int     circleCount()    const { return m_circles.size(); }
    bool    inGeofence()     const { return m_inGeofence; }
    bool    hasGeofence()    const { return m_hasGeofence; }
    double  geofenceLat()    const { return m_geofenceLat; }
    double  geofenceLng()    const { return m_geofenceLng; }
    double  geofenceRadius() const { return m_geofenceRadius; }

    Q_INVOKABLE QVariantList getMarkers()    const;
    Q_INVOKABLE QVariantList getTrace()      const;
    Q_INVOKABLE QVariantList getCircles()    const;
    Q_INVOKABLE QVariantMap  getLiveMarker() const;

public slots:
    void addMarker(double lat, double lng, QString label);
    void addMarkerWithPayload(double lat, double lng, QString label, QString payload);
    void addTracePoint(double lat, double lng);
    void setCenter(double lat, double lng, int zoom);
    void clearMarkers();
    void clearTrace();
    void clearAll();
    void setStartPoint(double lat, double lng);
    void setEndPoint(double lat, double lng);
    void removeMarkerAt(int index);
    void updateMarkerLabel(int index, QString label);
    // Live tracking
    void setLiveMarker(double lat, double lng, QString label = "Live");
    void clearLiveMarker();
    // Circles / geofence
    void addCircle(double lat, double lng, double radiusMeters,
                   QString label = "", QString color = "#3b82f6");
    void removeCircleAt(int index);
    void clearCircles();
    void setGeofence(double lat, double lng, double radiusMeters);
    void clearGeofence();

signals:
    // ── Node outputs (wired to other nodes) ──
    void markerClicked(double lat, double lng, QString label);
    void markerClickedWithPayload(double lat, double lng, QString label, QString payload);
    void mapClicked(double lat, double lng);
    void geofenceEntered(double lat, double lng);
    void geofenceExited(double lat, double lng);

    // ── QML bridge (excluded from node wiring) ──
    void internalMarkersChanged();
    void internalTraceChanged();
    void internalCenterChanged(double lat, double lng, int zoom);
    void internalClear();
    void internalLiveChanged();
    void internalCirclesChanged();
    void internalGeofenceConfigChanged();

    // ── Property notifiers ──
    void markerCountChanged();
    void traceLengthChanged();
    void centerChanged();
    void zoomChanged();
    void liveMarkerChanged();
    void circleCountChanged();
    void geofenceStateChanged();
    void geofenceConfigChanged();

private:
    void checkGeofence();

    QVector<MapMarker>  m_markers;
    QVector<QPointF>    m_trace;
    QVector<QPointF>    m_breadcrumb;
    QVector<MapCircle>  m_circles;

    MapMarker m_startPoint  {0, 0, "", ""};
    MapMarker m_endPoint    {0, 0, "", ""};
    MapMarker m_liveMarker  {0, 0, "Live", ""};
    bool      m_hasStart  = false;
    bool      m_hasEnd    = false;
    bool      m_hasLive   = false;

    double m_geofenceLat    = 0;
    double m_geofenceLng    = 0;
    double m_geofenceRadius = 0;
    bool   m_hasGeofence    = false;
    bool   m_inGeofence     = false;

    double m_centerLat = 48.8566;
    double m_centerLng = 2.3522;
    int    m_zoom      = 13;

    static constexpr int k_maxBreadcrumb = 60;
};

#endif // MAPVIEWER_H
