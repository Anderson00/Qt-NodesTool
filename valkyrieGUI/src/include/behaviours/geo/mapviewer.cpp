#include "mapviewer.h"
#include "behaviours/behaviourregistry.h"

#include <QJsonArray>
#include <QJsonObject>
#include <cmath>

REGISTER_BEHAVIOUR(MapViewer, "Map Viewer",
    "Interactive OSM tile map — markers, GPS traces, live tracking, circles and geofence",
    "geo", 12, 5)

MapViewer::MapViewer(QObject *parent) : Behaviours(parent)
{
    setWidth(420);
    setHeight(400);
    setContentHeight(400);
    setQmlBodyUrl("qrc:/behaviours/geo/MapViewer.qml");
    addInputOutputExclusion(QList<QString>({
        "internalMarkersChanged()",
        "internalTraceChanged()",
        "internalCenterChanged(double,double,int)",
        "internalClear()",
        "internalLiveChanged()",
        "internalCirclesChanged()",
        "internalGeofenceConfigChanged()"
    }));
}

QMap<QString, QVariant> MapViewer::loadInfos() { return MapViewer::static_infos(); }

QMap<QString, QVariant> MapViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "MapViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "MapViewer"},
        {"desc",          "Interactive OSM tile map — markers, GPS traces, live tracking, circles and geofence"},
        {"inputs_count",  "12"},
        {"outputs_count", "5"}
    });
}

// ── Markers ───────────────────────────────────────────────────────────────────

void MapViewer::addMarker(double lat, double lng, QString label)
{
    m_markers.append({lat, lng, label, ""});
    emit markerCountChanged();
    emit internalMarkersChanged();
}

void MapViewer::addMarkerWithPayload(double lat, double lng, QString label, QString payload)
{
    m_markers.append({lat, lng, label, payload});
    emit markerCountChanged();
    emit internalMarkersChanged();
}

void MapViewer::removeMarkerAt(int index)
{
    if (index < 0 || index >= m_markers.size()) return;
    m_markers.removeAt(index);
    emit markerCountChanged();
    emit internalMarkersChanged();
}

void MapViewer::updateMarkerLabel(int index, QString label)
{
    if (index < 0 || index >= m_markers.size()) return;
    m_markers[index].label = label;
    emit internalMarkersChanged();
}

void MapViewer::clearMarkers()
{
    m_markers.clear();
    m_hasStart = false;
    m_hasEnd   = false;
    emit markerCountChanged();
    emit internalMarkersChanged();
}

void MapViewer::setStartPoint(double lat, double lng)
{
    m_startPoint = {lat, lng, "Start", ""};
    m_hasStart   = true;
    emit internalMarkersChanged();
}

void MapViewer::setEndPoint(double lat, double lng)
{
    m_endPoint = {lat, lng, "End", ""};
    m_hasEnd   = true;
    emit internalMarkersChanged();
}

// ── Trace ─────────────────────────────────────────────────────────────────────

void MapViewer::addTracePoint(double lat, double lng)
{
    m_trace.append(QPointF(lng, lat));
    emit traceLengthChanged();
    emit internalTraceChanged();
}

void MapViewer::clearTrace()
{
    m_trace.clear();
    emit traceLengthChanged();
    emit internalTraceChanged();
}

void MapViewer::removeLastTracePoint()
{
    if (m_trace.isEmpty()) return;
    m_trace.removeLast();
    emit traceLengthChanged();
    emit internalTraceChanged();
}

// ── Live marker ───────────────────────────────────────────────────────────────

void MapViewer::setLiveMarker(double lat, double lng, QString label)
{
    if (m_hasLive) {
        m_breadcrumb.append(QPointF(m_liveMarker.lng, m_liveMarker.lat));
        if (m_breadcrumb.size() > k_maxBreadcrumb)
            m_breadcrumb.removeFirst();
    }
    m_liveMarker = {lat, lng, label, ""};
    m_hasLive    = true;
    emit liveMarkerChanged();
    emit internalLiveChanged();
    checkGeofence();
}

void MapViewer::clearLiveMarker()
{
    m_hasLive = false;
    m_breadcrumb.clear();
    emit liveMarkerChanged();
    emit internalLiveChanged();
}

// ── Circles ───────────────────────────────────────────────────────────────────

void MapViewer::addCircle(double lat, double lng, double radiusMeters,
                          QString label, QString color)
{
    m_circles.append({lat, lng, radiusMeters, label, color});
    emit circleCountChanged();
    emit internalCirclesChanged();
}

void MapViewer::removeCircleAt(int index)
{
    if (index < 0 || index >= m_circles.size()) return;
    m_circles.removeAt(index);
    emit circleCountChanged();
    emit internalCirclesChanged();
}

void MapViewer::clearCircles()
{
    m_circles.clear();
    emit circleCountChanged();
    emit internalCirclesChanged();
}

// ── Geofence ──────────────────────────────────────────────────────────────────

void MapViewer::setGeofence(double lat, double lng, double radiusMeters)
{
    m_geofenceLat    = lat;
    m_geofenceLng    = lng;
    m_geofenceRadius = radiusMeters;
    m_hasGeofence    = true;
    emit geofenceConfigChanged();
    emit internalGeofenceConfigChanged();
    checkGeofence();
}

void MapViewer::clearGeofence()
{
    m_hasGeofence = false;
    m_inGeofence  = false;
    emit geofenceConfigChanged();
    emit geofenceStateChanged();
    emit internalGeofenceConfigChanged();
}

void MapViewer::checkGeofence()
{
    if (!m_hasGeofence || !m_hasLive) return;

    const double R    = 6378137.0;
    double dLat = (m_liveMarker.lat - m_geofenceLat) * M_PI / 180.0;
    double dLng = (m_liveMarker.lng - m_geofenceLng) * M_PI / 180.0;
    double a    = std::sin(dLat/2)*std::sin(dLat/2)
                + std::cos(m_geofenceLat*M_PI/180.0)*std::cos(m_liveMarker.lat*M_PI/180.0)
                * std::sin(dLng/2)*std::sin(dLng/2);
    double dist = R * 2.0 * std::atan2(std::sqrt(a), std::sqrt(1.0 - a));

    bool nowInside = (dist <= m_geofenceRadius);
    if (nowInside != m_inGeofence) {
        m_inGeofence = nowInside;
        emit geofenceStateChanged();
        if (nowInside) emit geofenceEntered(m_liveMarker.lat, m_liveMarker.lng);
        else           emit geofenceExited(m_liveMarker.lat, m_liveMarker.lng);
    }
}

// ── Center / clear ────────────────────────────────────────────────────────────

void MapViewer::setCenter(double lat, double lng, int zoom)
{
    m_centerLat = lat;
    m_centerLng = lng;
    m_zoom      = zoom;
    emit centerChanged();
    emit zoomChanged();
    emit internalCenterChanged(lat, lng, zoom);
}

void MapViewer::clearAll()
{
    clearMarkers();
    clearTrace();
    clearLiveMarker();
    clearCircles();
    emit internalClear();
}

// ── Invokables ────────────────────────────────────────────────────────────────

QVariantList MapViewer::getMarkers() const
{
    QVariantList list;
    for (const auto& m : m_markers) {
        QVariantMap obj;
        obj["lat"]     = m.lat;
        obj["lng"]     = m.lng;
        obj["label"]   = m.label;
        obj["payload"] = m.payload;
        obj["type"]    = "marker";
        list.append(obj);
    }
    if (m_hasStart) {
        QVariantMap obj;
        obj["lat"] = m_startPoint.lat; obj["lng"] = m_startPoint.lng;
        obj["label"] = "Start"; obj["type"] = "start"; obj["payload"] = "";
        list.append(obj);
    }
    if (m_hasEnd) {
        QVariantMap obj;
        obj["lat"] = m_endPoint.lat; obj["lng"] = m_endPoint.lng;
        obj["label"] = "End"; obj["type"] = "end"; obj["payload"] = "";
        list.append(obj);
    }
    return list;
}

QVariantList MapViewer::getTrace() const
{
    QVariantList list;
    for (const auto& pt : m_trace) {
        QVariantMap obj;
        obj["lng"] = pt.x();
        obj["lat"] = pt.y();
        list.append(obj);
    }
    return list;
}

QVariantList MapViewer::getCircles() const
{
    QVariantList list;
    for (const auto& c : m_circles) {
        QVariantMap obj;
        obj["lat"]          = c.lat;
        obj["lng"]          = c.lng;
        obj["radiusMeters"] = c.radiusMeters;
        obj["label"]        = c.label;
        obj["color"]        = c.color;
        list.append(obj);
    }
    return list;
}

QVariantMap MapViewer::getLiveMarker() const
{
    QVariantMap obj;
    if (!m_hasLive) return obj;
    obj["lat"]   = m_liveMarker.lat;
    obj["lng"]   = m_liveMarker.lng;
    obj["label"] = m_liveMarker.label;
    QVariantList crumb;
    for (const auto& pt : m_breadcrumb) {
        QVariantMap p; p["lng"] = pt.x(); p["lat"] = pt.y();
        crumb.append(p);
    }
    obj["breadcrumb"] = crumb;
    return obj;
}

// ── Persistence ───────────────────────────────────────────────────────────────

QJsonObject MapViewer::saveState() const
{
    QJsonObject state;
    state["centerLat"] = m_centerLat;
    state["centerLng"] = m_centerLng;
    state["zoom"]      = m_zoom;

    QJsonArray markers;
    for (const auto& m : m_markers) {
        QJsonObject o;
        o["lat"] = m.lat; o["lng"] = m.lng;
        o["label"] = m.label; o["payload"] = m.payload;
        markers.append(o);
    }
    state["markers"] = markers;

    QJsonArray trace;
    for (const auto& pt : m_trace) {
        QJsonObject o; o["lat"] = pt.y(); o["lng"] = pt.x();
        trace.append(o);
    }
    state["trace"] = trace;

    QJsonArray circles;
    for (const auto& c : m_circles) {
        QJsonObject o;
        o["lat"] = c.lat; o["lng"] = c.lng;
        o["radiusMeters"] = c.radiusMeters;
        o["label"] = c.label; o["color"] = c.color;
        circles.append(o);
    }
    state["circles"] = circles;

    if (m_hasGeofence) {
        QJsonObject gf;
        gf["lat"] = m_geofenceLat; gf["lng"] = m_geofenceLng;
        gf["radius"] = m_geofenceRadius;
        state["geofence"] = gf;
    }
    return state;
}

void MapViewer::loadState(const QJsonObject& state)
{
    m_centerLat = state["centerLat"].toDouble(48.8566);
    m_centerLng = state["centerLng"].toDouble(2.3522);
    m_zoom      = state["zoom"].toInt(13);

    m_markers.clear();
    for (const auto& val : state["markers"].toArray()) {
        auto o = val.toObject();
        m_markers.append({o["lat"].toDouble(), o["lng"].toDouble(),
                          o["label"].toString(), o["payload"].toString()});
    }

    m_trace.clear();
    for (const auto& val : state["trace"].toArray()) {
        auto o = val.toObject();
        m_trace.append(QPointF(o["lng"].toDouble(), o["lat"].toDouble()));
    }

    m_circles.clear();
    for (const auto& val : state["circles"].toArray()) {
        auto o = val.toObject();
        m_circles.append({o["lat"].toDouble(), o["lng"].toDouble(),
                          o["radiusMeters"].toDouble(),
                          o["label"].toString(), o["color"].toString()});
    }

    if (state.contains("geofence")) {
        auto gf = state["geofence"].toObject();
        m_geofenceLat    = gf["lat"].toDouble();
        m_geofenceLng    = gf["lng"].toDouble();
        m_geofenceRadius = gf["radius"].toDouble();
        m_hasGeofence    = true;
    }

    emit markerCountChanged(); emit traceLengthChanged();
    emit centerChanged();      emit circleCountChanged();
    emit geofenceConfigChanged();
    emit internalMarkersChanged(); emit internalTraceChanged();
    emit internalCenterChanged(m_centerLat, m_centerLng, m_zoom);
    emit internalCirclesChanged(); emit internalGeofenceConfigChanged();
}
