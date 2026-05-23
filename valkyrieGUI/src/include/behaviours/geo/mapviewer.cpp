#include "mapviewer.h"
#include "behaviours/behaviourregistry.h"

#include <QJsonArray>
#include <QJsonObject>

REGISTER_BEHAVIOUR(MapViewer, "Map Viewer", "Interactive OSM tile map with markers and GPS traces", "geo", 8, 2)

MapViewer::MapViewer(QObject *parent) : Behaviours(parent)
{
    setWidth(400);
    setHeight(380);
    setContentHeight(380);
    setQmlBodyUrl("qrc:/behaviours/geo/MapViewer.qml");
    addInputOutputExclusion(QList<QString>({
        "internalMarkersChanged()",
        "internalTraceChanged()",
        "internalCenterChanged(double,double,int)",
        "internalClear()"
    }));
}

QMap<QString, QVariant> MapViewer::loadInfos() { return MapViewer::static_infos(); }

QMap<QString, QVariant> MapViewer::static_infos()
{
    return QMap<QString, QVariant>({
        {"name",          "MapViewer"},
        {"type",          Behaviours::Type::CPP},
        {"className",     "MapViewer"},
        {"desc",          "Interactive OSM tile map with markers and GPS traces"},
        {"inputs_count",  "8"},
        {"outputs_count", "2"}
    });
}

// ── Public slots ──────────────────────────────────────────────────────────────

void MapViewer::addMarker(double lat, double lng, QString label)
{
    m_markers.append({lat, lng, label});
    emit markerCountChanged();
    emit internalMarkersChanged();
}

void MapViewer::addTracePoint(double lat, double lng)
{
    m_trace.append(QPointF(lng, lat));
    emit traceLengthChanged();
    emit internalTraceChanged();
}

void MapViewer::setCenter(double lat, double lng, int zoom)
{
    m_centerLat = lat;
    m_centerLng = lng;
    m_zoom      = zoom;
    emit centerChanged();
    emit zoomChanged();
    emit internalCenterChanged(lat, lng, zoom);
}

void MapViewer::clearMarkers()
{
    m_markers.clear();
    m_hasStart = false;
    m_hasEnd   = false;
    emit markerCountChanged();
    emit internalMarkersChanged();
}

void MapViewer::clearTrace()
{
    m_trace.clear();
    emit traceLengthChanged();
    emit internalTraceChanged();
}

void MapViewer::clearAll()
{
    clearMarkers();
    clearTrace();
    emit internalClear();
}

void MapViewer::setStartPoint(double lat, double lng)
{
    m_startPoint = {lat, lng, "Start"};
    m_hasStart   = true;
    emit internalMarkersChanged();
}

void MapViewer::setEndPoint(double lat, double lng)
{
    m_endPoint = {lat, lng, "End"};
    m_hasEnd   = true;
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

// ── Invokables ────────────────────────────────────────────────────────────────

QVariantList MapViewer::getMarkers() const
{
    QVariantList list;
    for (const auto& m : m_markers) {
        QVariantMap obj;
        obj["lat"]   = m.lat;
        obj["lng"]   = m.lng;
        obj["label"] = m.label;
        obj["type"]  = "marker";
        list.append(obj);
    }
    if (m_hasStart) {
        QVariantMap obj;
        obj["lat"] = m_startPoint.lat; obj["lng"] = m_startPoint.lng;
        obj["label"] = "Start"; obj["type"] = "start";
        list.append(obj);
    }
    if (m_hasEnd) {
        QVariantMap obj;
        obj["lat"] = m_endPoint.lat; obj["lng"] = m_endPoint.lng;
        obj["label"] = "End"; obj["type"] = "end";
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

// ── Persistence ───────────────────────────────────────────────────────────────

QJsonObject MapViewer::saveState() const
{
    QJsonObject state;
    state["centerLat"] = m_centerLat;
    state["centerLng"] = m_centerLng;
    state["zoom"]      = m_zoom;

    QJsonArray markers;
    for (const auto& m : m_markers) {
        QJsonObject obj;
        obj["lat"] = m.lat; obj["lng"] = m.lng; obj["label"] = m.label;
        markers.append(obj);
    }
    state["markers"] = markers;

    QJsonArray trace;
    for (const auto& pt : m_trace) {
        QJsonObject obj;
        obj["lat"] = pt.y(); obj["lng"] = pt.x();
        trace.append(obj);
    }
    state["trace"] = trace;
    return state;
}

void MapViewer::loadState(const QJsonObject& state)
{
    m_centerLat = state["centerLat"].toDouble(48.8566);
    m_centerLng = state["centerLng"].toDouble(2.3522);
    m_zoom      = state["zoom"].toInt(13);

    m_markers.clear();
    for (const auto& val : state["markers"].toArray()) {
        auto obj = val.toObject();
        m_markers.append({obj["lat"].toDouble(), obj["lng"].toDouble(), obj["label"].toString()});
    }

    m_trace.clear();
    for (const auto& val : state["trace"].toArray()) {
        auto obj = val.toObject();
        m_trace.append(QPointF(obj["lng"].toDouble(), obj["lat"].toDouble()));
    }

    emit markerCountChanged();
    emit traceLengthChanged();
    emit centerChanged();
    emit internalMarkersChanged();
    emit internalTraceChanged();
    emit internalCenterChanged(m_centerLat, m_centerLng, m_zoom);
}
