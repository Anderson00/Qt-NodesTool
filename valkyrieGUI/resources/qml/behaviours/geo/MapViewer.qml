import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    // ── Map state ─────────────────────────────────────────────────────────────
    property double centerLat:  behaviourObject ? behaviourObject.centerLat : 48.8566
    property double centerLng:  behaviourObject ? behaviourObject.centerLng : 2.3522
    property int    zoom:       behaviourObject ? behaviourObject.zoom      : 4
    property var    markers:    []
    property var    trace:      []
    property var    circles:    []
    property var    liveMarker: null

    // ── Active mode (one at a time) ───────────────────────────────────────────
    // "": none  "marker" "circle" "trace" "measure" "live"
    property string activeMode: ""
    property bool addMarkerMode: activeMode === "marker"
    property bool addCircleMode: activeMode === "circle"
    property bool addTraceMode:  activeMode === "trace"
    property bool measureMode:   activeMode === "measure"
    property bool showLivePanel: activeMode === "live"

    // ── Measure state ─────────────────────────────────────────────────────────
    property var    measurePts:    []
    property double measureCurLat: 0
    property double measureCurLng: 0

    // ── Hover / drag ──────────────────────────────────────────────────────────
    property int    hoveredMarkerIdx: -1
    property double hoverLat:         0
    property double hoverLng:         0
    property real   dragStartX:   0
    property real   dragStartY:   0
    property real   dragStartLat: 0
    property real   dragStartLng: 0
    property bool   isDragging:   false

    // ── Live pulse ────────────────────────────────────────────────────────────
    property real pulsePhase: 0
    Timer {
        id: pulseTimer; interval: 55; repeat: true; running: root.liveMarker !== null
        onTriggered: { root.pulsePhase = (root.pulsePhase + 0.04) % 1.0; overlayCanvas.requestPaint() }
    }

    // ── Map styles ────────────────────────────────────────────────────────────
    property string mapStyle: "osm"
    readonly property var styleList: [
        { id: "osm",            label: "Streets"      },
        { id: "carto-light",    label: "Voyager"      },
        { id: "carto-positron", label: "Positron"     },
        { id: "carto-dark",     label: "Dark"         },
        { id: "esri-satellite", label: "Satélite"     },
        { id: "esri-streets",   label: "Esri Streets" },
        { id: "topo",           label: "Topo"         },
        { id: "osm-hot",        label: "Humanitário"  },
        { id: "wikimedia",      label: "Wikimedia"    }
    ]
    property bool isDark: mapStyle === "carto-dark" || mapStyle === "esri-satellite"

    // ── Scale bar ─────────────────────────────────────────────────────────────
    property var scaleInfo: {
        var mpx = (Math.cos(centerLat*Math.PI/180)*2*Math.PI*6378137)/(Math.pow(2,zoom)*256)
        var t   = mpx * 80
        var ss  = [1,2,5,10,20,50,100,200,500,1000,2000,5000,10000,50000,100000]
        var b = ss[0]; for (var i=0;i<ss.length;i++){b=ss[i];if(ss[i]>=t)break}
        return { px: Math.round(b/mpx), label: b>=1000?(b/1000)+" km":b+" m" }
    }

    // ── Tile URLs ─────────────────────────────────────────────────────────────
    function tileUrl(z,x,y) {
        switch (mapStyle) {
        case "carto-light":    return "https://basemaps.cartocdn.com/rastertiles/voyager/"  +z+"/"+x+"/"+y+".png"
        case "carto-positron": return "https://basemaps.cartocdn.com/light_all/"            +z+"/"+x+"/"+y+".png"
        case "carto-dark":     return "https://basemaps.cartocdn.com/dark_all/"             +z+"/"+x+"/"+y+".png"
        case "topo":           return "https://tile.opentopomap.org/"                       +z+"/"+x+"/"+y+".png"
        case "esri-satellite": return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/"    +z+"/"+y+"/"+x
        case "esri-streets":   return "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/" +z+"/"+y+"/"+x
        case "osm-hot":        return "https://tile.openstreetmap.fr/hot/"                  +z+"/"+x+"/"+y+".png"
        case "wikimedia":      return "https://maps.wikimedia.org/osm-intl/"                +z+"/"+x+"/"+y+".png"
        default:               return "https://tile.openstreetmap.org/"                     +z+"/"+x+"/"+y+".png"
        }
    }
    function mapBg()    { if(mapStyle==="esri-satellite")return"#080808"; if(mapStyle==="carto-dark")return"#1a1a2e"; return"#c8dff0" }
    function attrib()   { if(mapStyle==="esri-satellite"||mapStyle==="esri-streets")return"© Esri"; if(mapStyle==="wikimedia")return"© Wikimedia | © OSM"; if(mapStyle==="osm-hot")return"© OpenStreetMap | HOT"; return"© OpenStreetMap contributors" }

    // ── Projection helpers ────────────────────────────────────────────────────
    function lon2tile(lng,z){ return Math.floor((lng+180)/360*Math.pow(2,z)) }
    function lat2tile(lat,z){ return Math.floor((1-Math.log(Math.tan(lat*Math.PI/180)+1/Math.cos(lat*Math.PI/180))/Math.PI)/2*Math.pow(2,z)) }
    function latLngToPixel(lat,lng) {
        var ts=256,sc=Math.pow(2,zoom)*ts
        var px=(lng+180)/360*sc, pxC=(centerLng+180)/360*sc
        var py=(1-Math.log(Math.tan(Math.PI/4+lat*Math.PI/360))/Math.PI)/2*sc
        var pyC=(1-Math.log(Math.tan(Math.PI/4+centerLat*Math.PI/360))/Math.PI)/2*sc
        return Qt.point(mapClip.width/2+(px-pxC), mapClip.height/2+(py-pyC))
    }
    function pixelToLatLng(sx,sy) {
        var ts=256,sc=Math.pow(2,zoom)*ts
        var dx=sx-mapClip.width/2, dy=sy-mapClip.height/2
        var lng=centerLng+dx/sc*360
        var cPy=(1-Math.log(Math.tan(Math.PI/4+centerLat*Math.PI/360))/Math.PI)/2
        var nPy=Math.max(0.001,Math.min(0.999,cPy+dy/sc))
        return Qt.point(180/Math.PI*(2*Math.atan(Math.exp((1-2*nPy)*Math.PI))-Math.PI/2), lng)
    }
    function metersToPixels(lat,m){ return m/((Math.cos(lat*Math.PI/180)*2*Math.PI*6378137)/(Math.pow(2,zoom)*256)) }
    function haversineKm(la1,ln1,la2,ln2) {
        var R=6371,dLa=(la2-la1)*Math.PI/180,dLn=(ln2-ln1)*Math.PI/180
        var a=Math.sin(dLa/2)*Math.sin(dLa/2)+Math.cos(la1*Math.PI/180)*Math.cos(la2*Math.PI/180)*Math.sin(dLn/2)*Math.sin(dLn/2)
        return R*2*Math.atan2(Math.sqrt(a),Math.sqrt(1-a))
    }
    function fmtDist(km){ return km<1?Math.round(km*1000)+" m":km.toFixed(2)+" km" }
    function nearestMarker(mx,my,thr) {
        var best=-1,bd=thr*thr
        for(var i=0;i<root.markers.length;i++){var mp=root.latLngToPixel(root.markers[i].lat,root.markers[i].lng);var d=(mx-mp.x)*(mx-mp.x)+(my-(mp.y-11))*(my-(mp.y-11));if(d<bd){bd=d;best=i}}
        return best
    }

    // ── C++ bridge ────────────────────────────────────────────────────────────
    Connections {
        target: behaviourObject
        function onInternalMarkersChanged()        { if(behaviourObject)root.markers=behaviourObject.getMarkers(); root.hoveredMarkerIdx=-1; overlayCanvas.requestPaint() }
        function onInternalTraceChanged()          { if(behaviourObject)root.trace=behaviourObject.getTrace(); overlayCanvas.requestPaint() }
        function onInternalCenterChanged(la,ln,z)  { root.centerLat=la;root.centerLng=ln;root.zoom=z; tileLayer.fullRefresh();overlayCanvas.requestPaint() }
        function onInternalClear()                 { root.markers=[];root.trace=[];root.liveMarker=null;root.circles=[]; tileLayer.fullRefresh();overlayCanvas.requestPaint() }
        function onInternalLiveChanged()           { root.liveMarker=behaviourObject&&behaviourObject.hasLiveMarker?behaviourObject.getLiveMarker():null; overlayCanvas.requestPaint() }
        function onInternalCirclesChanged()        { if(behaviourObject)root.circles=behaviourObject.getCircles(); overlayCanvas.requestPaint() }
        function onInternalGeofenceConfigChanged() { overlayCanvas.requestPaint() }
    }
    Component.onCompleted: tileLayer.fullRefresh()

    // =========================================================================
    // ── Floating popups (root level — ABOVE everything, no z-clipping issues) ─
    // =========================================================================

    // ── Style dropdown (FIX: at root level, z:1000) ───────────────────────────
    Rectangle {
        id: styleDropdown
        visible: false; z: 1000
        width: 140; radius: 7
        height: styleCol.implicitHeight + 8
        color: ThemeManager.surfaceColor
        border.color: ThemeManager.borderColor; border.width: 1
        // shadow
        layer.enabled: true
        layer.effect: null   // simple drop shadow not needed — border suffices

        Column {
            id: styleCol
            anchors { fill: parent; margins: 4 }
            spacing: 1
            Repeater {
                model: root.styleList
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width; height: 24; radius: 4
                    color: root.mapStyle===modelData.id
                           ? Qt.rgba(ThemeManager.primaryColor.r,ThemeManager.primaryColor.g,ThemeManager.primaryColor.b,0.14)
                           : (sh.containsMouse ? Qt.rgba(0.5,0.5,0.5,0.08) : "transparent")
                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8 }
                        text: modelData.label
                        color: root.mapStyle===modelData.id ? ThemeManager.primaryColor : ThemeManager.textColor
                        font.pixelSize: 10
                    }
                    MouseArea {
                        id: sh; anchors.fill: parent; hoverEnabled: true
                        onClicked: { root.mapStyle=modelData.id; styleDropdown.visible=false; tileLayer.fullRefresh() }
                    }
                }
            }
        }
        MouseArea { anchors.fill: parent; onClicked: {} }  // eat clicks so map doesn't get them
    }

    // ── Marker label popup ─────────────────────────────────────────────────────
    Rectangle {
        id: markerPopup; visible: false; z: 1000
        width: 216; height: 74; radius: 8
        color: ThemeManager.surfaceColor; border.color: "#22c55e"; border.width: 1.5
        property real  pendingLat: 0; property real pendingLng: 0
        property alias labelField: lblIn
        Column {
            anchors { fill: parent; margins: 10 }
            spacing: 6
            Text {
                text: "Label do marcador (opcional)"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
            }
            Row { spacing: 6; width: parent.width
                Rectangle { width: parent.width-58; height: 24; radius: 4; color: ThemeManager.backgroundColor; border.color: ThemeManager.borderColor
                    TextInput {
                        id: lblIn
                        anchors { fill: parent; leftMargin: 7; rightMargin: 7; topMargin: 4; bottomMargin: 4 }
                        color: ThemeManager.textColor
                        font.pixelSize: 11
                        Keys.onReturnPressed: markerPopup.confirm()
                        Keys.onEscapePressed: markerPopup.visible = false
                    }
                }
                Rectangle { width:52;height:24;radius:4;color:"#22c55e"
                    Text{anchors.centerIn:parent;text:"Add";color:"white";font.pixelSize:10;font.bold:true}
                    MouseArea{anchors.fill:parent;onClicked:markerPopup.confirm()} }
            }
        }
        function confirm() { if(behaviourObject)behaviourObject.addMarker(pendingLat,pendingLng,lblIn.text||""); visible=false; root.activeMode="" }
    }

    // ── Circle popup ───────────────────────────────────────────────────────────
    Rectangle {
        id: circlePopup; visible: false; z: 1000
        width: 234; height: 154; radius: 8
        color: ThemeManager.surfaceColor; border.color: "#3b82f6"; border.width: 1.5
        property real   pendingLat: 0; property real pendingLng: 0
        property string selectedColor: "#3b82f6"
        property bool   asGeofence: false

        Column {
            anchors { fill: parent; margins: 10 }
            spacing: 6
            Text { text: "Novo círculo"; color: ThemeManager.textColor; font.pixelSize: 10; font.bold: true }

            // Coord display
            Text {
                text: circlePopup.pendingLat.toFixed(5) + ",  " + circlePopup.pendingLng.toFixed(5)
                color: ThemeManager.textSecondaryColor; font.pixelSize: 9; font.family: "Consolas, monospace"
            }

            // Radius + Label row
            Row { spacing: 6; width: parent.width
                Rectangle { width: 90; height: 24; radius: 4; color: ThemeManager.backgroundColor; border.color: ThemeManager.borderColor
                    Row {
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                        spacing: 3
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "R:"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                        TextInput {
                            id: radiusIn
                            anchors.verticalCenter: parent.verticalCenter
                            width: 58
                            color: ThemeManager.textColor
                            font.pixelSize: 11
                            text: "500"
                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                            validator: DoubleValidator { bottom: 1; top: 10000000 }
                            Keys.onReturnPressed: circlePopup.confirm()
                            Keys.onEscapePressed: circlePopup.visible = false
                        }
                    }
                }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "m"; color: ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                Rectangle { width: parent.width-106; height: 24; radius: 4; color: ThemeManager.backgroundColor; border.color: ThemeManager.borderColor
                    TextField {
                        id: circleLblIn
                        anchors { fill: parent; leftMargin: 7; rightMargin: 7; topMargin: 4; bottomMargin: 4 }
                        color: ThemeManager.textColor
                        font.pixelSize: 11
                        placeholderText: "Label…"
                        placeholderTextColor: ThemeManager.textSecondaryColor
                        background: null
                        padding: 0
                        Keys.onReturnPressed: circlePopup.confirm()
                        Keys.onEscapePressed: circlePopup.visible = false
                    }
                }
            }

            // Color swatches
            Row { spacing: 5
                Repeater {
                    model: ["#3b82f6","#22c55e","#f59e0b","#ef4444","#8b5cf6"]
                    delegate: Rectangle {
                        required property var modelData
                        width: 20; height: 20; radius: 10; color: modelData
                        border.color: circlePopup.selectedColor===modelData ? "white" : "transparent"; border.width: 2
                        MouseArea { anchors.fill: parent; onClicked: circlePopup.selectedColor=modelData }
                        Rectangle { anchors.centerIn: parent; width: 7; height: 7; radius: 4; color: "white"
                            visible: circlePopup.selectedColor===modelData }
                    }
                }
                Item { width: 6 }
                Rectangle {   // Geofence toggle
                    width: geofTxt.width + 22; height: 20; radius: 4
                    color: circlePopup.asGeofence ? Qt.rgba(0.24,0.8,0.44,0.18) : Qt.rgba(0.5,0.5,0.5,0.08)
                    border.color: circlePopup.asGeofence ? "#22c55e" : ThemeManager.borderColor; border.width: 1
                    Row { anchors.centerIn: parent; spacing: 4
                        Rectangle { width: 8; height: 8; radius: 4; color: circlePopup.asGeofence ? "#22c55e" : ThemeManager.textSecondaryColor }
                        Text { id: geofTxt; text: "Geofence"; color: circlePopup.asGeofence ? "#22c55e" : ThemeManager.textSecondaryColor; font.pixelSize: 9 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: circlePopup.asGeofence = !circlePopup.asGeofence }
                }
            }

            // Action buttons
            Row { spacing: 6; anchors.right: parent.right
                Rectangle { width: 52; height: 24; radius: 4; color: ThemeManager.borderColor
                    Text{anchors.centerIn:parent;text:"Cancelar";color:ThemeManager.textSecondaryColor;font.pixelSize:9}
                    MouseArea{anchors.fill:parent;onClicked:circlePopup.visible=false} }
                Rectangle { width: 64; height: 24; radius: 4; color: "#3b82f6"
                    Text{anchors.centerIn:parent;text:"Adicionar";color:"white";font.pixelSize:9;font.bold:true}
                    MouseArea{anchors.fill:parent;onClicked:circlePopup.confirm()} }
            }
        }

        function confirm() {
            if (!behaviourObject) { visible=false; return }
            var r = parseFloat(radiusIn.text) || 500
            if (asGeofence) {
                behaviourObject.setGeofence(pendingLat, pendingLng, r)
            } else {
                behaviourObject.addCircle(pendingLat, pendingLng, r, circleLblIn.text||"", selectedColor)
            }
            visible = false; root.activeMode = ""
        }
    }

    // ── Close dropdowns on outside click ──────────────────────────────────────
    MouseArea {
        anchors.fill: parent; z: 999; visible: styleDropdown.visible
        onClicked: styleDropdown.visible = false
    }
    MouseArea {
        anchors.fill: parent; z: 999; visible: circlePopup.visible || markerPopup.visible
        onClicked: { circlePopup.visible=false; markerPopup.visible=false }
    }

    // =========================================================================
    // ── Main layout ──────────────────────────────────────────────────────────
    // =========================================================================
    ColumnLayout { anchors.fill: parent; spacing: 0

        // ── Toolbar ─────────────────────────────────────────────────────────
        Rectangle {
            id: toolbarRect
            Layout.fillWidth: true; height: 36
            color: ThemeManager.surfaceColor
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: ThemeManager.borderColor }

            RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                spacing: 4

                Text { text: "Map"; color: ThemeManager.textColor; font.pixelSize: 11; font.bold: true }

                // Style button (FIX: opens root-level dropdown to avoid z-clipping)
                Rectangle {
                    id: styleBtnRect
                    width: styleBtnTxt.width + 22; height: 24; radius: 4
                    color: styleDropdown.visible ? Qt.rgba(ThemeManager.primaryColor.r,ThemeManager.primaryColor.g,ThemeManager.primaryColor.b,0.12) : "transparent"
                    border.color: styleDropdown.visible ? ThemeManager.primaryColor : ThemeManager.borderColor; border.width: 1
                    Row {
                        anchors { fill: parent; leftMargin: 7; rightMargin: 5 }
                        spacing: 4
                        Text {
                            id: styleBtnTxt
                            text: { for(var i=0;i<root.styleList.length;i++) if(root.styleList[i].id===root.mapStyle) return root.styleList[i].label; return root.mapStyle }
                            color: ThemeManager.textColor; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter
                        }
                        Text { text: "▾"; color: ThemeManager.textSecondaryColor; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (styleDropdown.visible) { styleDropdown.visible = false; return }
                            // Position dropdown below this button at root-level coordinates
                            var pos = styleBtnRect.mapToItem(root, 0, styleBtnRect.height + 2)
                            styleDropdown.x = Math.min(pos.x, root.width - styleDropdown.width - 4)
                            styleDropdown.y = pos.y
                            styleDropdown.visible = true
                        }
                    }
                }

                Rectangle { width: 1; height: 20; color: ThemeManager.borderColor; opacity: 0.5 }

                // ── Mode buttons ────────────────────────────────────────────
                Repeater {
                    model: [
                        { mode: "marker",  icon: "⊕", col: "#22c55e", tip: "Marcador"   },
                        { mode: "circle",  icon: "◎", col: "#3b82f6", tip: "Círculo"    },
                        { mode: "trace",   icon: "⤳", col: "#8b5cf6", tip: "Trace"      },
                        { mode: "measure", icon: "↔", col: "#f59e0b", tip: "Medir"      },
                        { mode: "live",    icon: "●", col: "#10b981", tip: "Live marker" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        property bool active: root.activeMode === modelData.mode
                        width: 26; height: 24; radius: 4
                        color: active ? Qt.rgba(...modelData.col.match(/\w\w/g).map((h,i)=>parseInt(h,16)/255).concat([0.15])) : "transparent"
                        border.color: active ? modelData.col : ThemeManager.borderColor; border.width: 1
                        Text {
                            anchors.centerIn: parent; text: modelData.icon
                            color: active ? modelData.col : ThemeManager.textSecondaryColor
                            font.pixelSize: modelData.mode==="live" ? 10 : 13
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.activeMode = (root.activeMode===modelData.mode ? "" : modelData.mode)
                                root.measurePts = []
                                styleDropdown.visible=false; circlePopup.visible=false; markerPopup.visible=false
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Zoom controls
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: zmH.containsMouse ? Qt.rgba(0.5,0.5,0.5,0.12) : "transparent"; border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "−"; color: ThemeManager.textColor; font.pixelSize: 16; font.bold: true }
                    MouseArea { id: zmH; anchors.fill: parent; hoverEnabled: true
                        onClicked: if(root.zoom>1){root.zoom--;tileLayer.fullRefresh();overlayCanvas.requestPaint()} }
                }
                Text { text: root.zoom; color: ThemeManager.textColor; font.pixelSize: 11; width: 20; horizontalAlignment: Text.AlignHCenter }
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: zpH.containsMouse ? Qt.rgba(0.5,0.5,0.5,0.12) : "transparent"; border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "+"; color: ThemeManager.textColor; font.pixelSize: 16; font.bold: true }
                    MouseArea { id: zpH; anchors.fill: parent; hoverEnabled: true
                        onClicked: if(root.zoom<19){root.zoom++;tileLayer.fullRefresh();overlayCanvas.requestPaint()} }
                }

                Rectangle { width: 1; height: 20; color: ThemeManager.borderColor; opacity: 0.5 }

                Rectangle {
                    width: 40; height: 24; radius: 4
                    color: clH.containsMouse ? Qt.rgba(0.5,0.5,0.5,0.12) : "transparent"; border.color: ThemeManager.borderColor
                    Text { anchors.centerIn: parent; text: "Clear"; color: ThemeManager.textSecondaryColor; font.pixelSize: 10 }
                    MouseArea { id: clH; anchors.fill: parent; hoverEnabled: true; onClicked: if(behaviourObject)behaviourObject.clearAll() }
                }
            }
        }

        // ── Live panel (collapsible) ──────────────────────────────────────────
        Rectangle {
            id: livePanelRect
            Layout.fillWidth: true
            height: root.showLivePanel ? 36 : 0
            clip: true
            color: Qt.rgba(0.063,0.725,0.506,0.08)
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#10b981"; opacity: 0.4 }

            RowLayout {
                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                spacing: 6
                visible: root.showLivePanel

                Text { text: "●"; color: "#10b981"; font.pixelSize: 10 }
                Text { text: "Live"; color: "#10b981"; font.pixelSize: 10; font.bold: true }

                function fieldBox(w) { return w }

                Rectangle { width: 80; height: 22; radius: 4; color: ThemeManager.backgroundColor; border.color: ThemeManager.borderColor
                    TextField {
                        id: liveLat
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 3; bottomMargin: 3 }
                        color: ThemeManager.textColor
                        font.pixelSize: 10
                        placeholderText: "Lat"
                        placeholderTextColor: ThemeManager.textSecondaryColor
                        background: null
                        padding: 0
                        text: root.liveMarker ? root.liveMarker.lat.toFixed(5) : ""
                        validator: DoubleValidator { bottom: -90; top: 90 }
                    }
                }

                Rectangle { width: 80; height: 22; radius: 4; color: ThemeManager.backgroundColor; border.color: ThemeManager.borderColor
                    TextField {
                        id: liveLng
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 3; bottomMargin: 3 }
                        color: ThemeManager.textColor
                        font.pixelSize: 10
                        placeholderText: "Lng"
                        placeholderTextColor: ThemeManager.textSecondaryColor
                        background: null
                        padding: 0
                        text: root.liveMarker ? root.liveMarker.lng.toFixed(5) : ""
                        validator: DoubleValidator { bottom: -180; top: 180 }
                    }
                }

                Rectangle { width: 70; height: 22; radius: 4; color: ThemeManager.backgroundColor; border.color: ThemeManager.borderColor
                    TextField {
                        id: liveLabel
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 3; bottomMargin: 3 }
                        color: ThemeManager.textColor
                        font.pixelSize: 10
                        placeholderText: "Label"
                        placeholderTextColor: ThemeManager.textSecondaryColor
                        background: null
                        padding: 0
                        text: root.liveMarker ? root.liveMarker.label : "Live"
                    }
                }

                Rectangle { width: 52; height: 22; radius: 4; color: "#10b981"
                    Text{anchors.centerIn:parent;text:"Atualizar";color:"white";font.pixelSize:9;font.bold:true}
                    MouseArea{anchors.fill:parent;onClicked:{
                        if(behaviourObject){
                            var la=parseFloat(liveLat.text);var ln=parseFloat(liveLng.text)
                            if(!isNaN(la)&&!isNaN(ln)) behaviourObject.setLiveMarker(la,ln,liveLabel.text||"Live")
                        }
                    }}
                }
                Rectangle { width: 40; height: 22; radius: 4; color: "transparent"; border.color: ThemeManager.borderColor; border.width: 1
                    Text{anchors.centerIn:parent;text:"Limpar";color:ThemeManager.textSecondaryColor;font.pixelSize:9}
                    MouseArea{anchors.fill:parent;onClicked:{if(behaviourObject)behaviourObject.clearLiveMarker()}} }
                Rectangle { width: 24; height: 22; radius: 4; color: "transparent"; border.color: ThemeManager.borderColor; border.width: 1
                    Text{anchors.centerIn:parent;text:"→";color:ThemeManager.textSecondaryColor;font.pixelSize:11}
                    MouseArea{anchors.fill:parent;onClicked:{
                        if(root.liveMarker){root.centerLat=root.liveMarker.lat;root.centerLng=root.liveMarker.lng;tileLayer.fullRefresh();overlayCanvas.requestPaint()}
                    }}
                }
            }
        }

        // ── Map clip ──────────────────────────────────────────────────────────
        Rectangle {
            id: mapClip
            Layout.fillWidth: true; Layout.fillHeight: true
            color: root.mapBg(); clip: true; focus: true

            Keys.onPressed: function(ev) {
                var step=40,sc=Math.pow(2,root.zoom)*256
                function sLat(dy){var cpy=(1-Math.log(Math.tan(Math.PI/4+root.centerLat*Math.PI/360))/Math.PI)/2;var npy=Math.max(0.001,Math.min(0.999,cpy+dy/sc));root.centerLat=180/Math.PI*(2*Math.atan(Math.exp((1-2*npy)*Math.PI))-Math.PI/2)}
                if(ev.key===Qt.Key_Left ||ev.key===Qt.Key_A){root.centerLng-=step/sc*360;tileLayer.fullRefresh();overlayCanvas.requestPaint()}
                if(ev.key===Qt.Key_Right||ev.key===Qt.Key_D){root.centerLng+=step/sc*360;tileLayer.fullRefresh();overlayCanvas.requestPaint()}
                if(ev.key===Qt.Key_Up   ||ev.key===Qt.Key_W){sLat(-step);tileLayer.fullRefresh();overlayCanvas.requestPaint()}
                if(ev.key===Qt.Key_Down ||ev.key===Qt.Key_S){sLat( step);tileLayer.fullRefresh();overlayCanvas.requestPaint()}
                if(ev.key===Qt.Key_Plus ||ev.key===Qt.Key_Equal){if(root.zoom<19){root.zoom++;tileLayer.fullRefresh();overlayCanvas.requestPaint()}}
                if(ev.key===Qt.Key_Minus){if(root.zoom>1){root.zoom--;tileLayer.fullRefresh();overlayCanvas.requestPaint()}}
                if(ev.key===Qt.Key_Escape){root.activeMode="";root.measurePts=[];styleDropdown.visible=false;circlePopup.visible=false;markerPopup.visible=false;overlayCanvas.requestPaint()}
            }

            // ── Tile layer (Translate fix — no anchors conflict) ───────────────
            Item {
                id: tileLayer; anchors.fill: parent
                Item { id: prevLayer; width: parent.width; height: parent.height; transform: Translate { id: prevTx } }
                Item { id: currLayer; width: parent.width; height: parent.height; transform: Translate { id: currTx } }
                property var prevTiles: []; property var currTiles: []

                Timer { id: prevClean; interval: 900; onTriggered: { for(var i=0;i<tileLayer.prevTiles.length;i++)tileLayer.prevTiles[i].destroy(); tileLayer.prevTiles=[] } }
                function panBy(dx,dy){ currTx.x=dx;currTx.y=dy;prevTx.x=dx;prevTx.y=dy }
                function fullRefresh() {
                    currTx.x=0;currTx.y=0;prevTx.x=0;prevTx.y=0
                    prevClean.stop()
                    for(var k=0;k<prevTiles.length;k++)prevTiles[k].destroy()
                    prevTiles=currTiles; for(var j=0;j<prevTiles.length;j++)prevTiles[j].parent=prevLayer; currTiles=[]; prevClean.restart()
                    var ts=256,mx=Math.pow(2,root.zoom),cTX=root.lon2tile(root.centerLng,root.zoom),cTY=root.lat2tile(root.centerLat,root.zoom)
                    var tiW=Math.ceil(currLayer.width/ts)+3,tiH=Math.ceil(currLayer.height/ts)+3
                    var subX=(root.centerLng+180)/360*mx*ts-cTX*ts
                    var cPy=(1-Math.log(Math.tan(Math.PI/4+root.centerLat*Math.PI/360))/Math.PI)/2
                    var subY=cPy*mx*ts-cTY*ts
                    var oX=currLayer.width/2-subX,oY=currLayer.height/2-subY
                    for(var dx2=-Math.floor(tiW/2)-1;dx2<=Math.ceil(tiW/2)+1;dx2++)
                        for(var dy2=-Math.floor(tiH/2)-1;dy2<=Math.ceil(tiH/2)+1;dy2++){
                            var tx=((cTX+dx2)%mx+mx)%mx,ty=cTY+dy2
                            if(ty<0||ty>=mx)continue
                            var obj=tileComp.createObject(currLayer,{x:oX+dx2*ts,y:oY+dy2*ts,source:root.tileUrl(root.zoom,tx,ty)})
                            if(obj)currTiles.push(obj)
                        }
                }
                Component { id: tileComp
                    Image {
                        width: 256; height: 256; fillMode: Image.Stretch; cache: true; smooth: true; asynchronous: true
                        opacity: 0
                        Behavior on opacity { NumberAnimation { duration: 140 } }
                        onStatusChanged: if(status === Image.Ready) opacity = 1
                    }
                }
            }

            // ── Overlay canvas ─────────────────────────────────────────────────
            Canvas {
                id: overlayCanvas; anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d"); ctx.clearRect(0,0,width,height)

                    // Circles
                    for(var ci=0;ci<root.circles.length;ci++){
                        var c=root.circles[ci],cp=root.latLngToPixel(c.lat,c.lng),rPx=root.metersToPixels(c.lat,c.radiusMeters),cc=c.color||"#3b82f6"
                        ctx.beginPath();ctx.arc(cp.x,cp.y,rPx,0,2*Math.PI);ctx.fillStyle=cc+"2a";ctx.fill();ctx.strokeStyle=cc;ctx.lineWidth=2;ctx.stroke()
                        ctx.beginPath();ctx.arc(cp.x,cp.y,4,0,2*Math.PI);ctx.fillStyle=cc;ctx.fill()
                        if(c.label){ctx.font="bold 10px sans-serif";ctx.textAlign="center";var ltw=ctx.measureText(c.label).width;ctx.fillStyle=root.isDark?"rgba(0,0,0,0.75)":"rgba(255,255,255,0.88)";ctx.beginPath();if(ctx.roundRect)ctx.roundRect(cp.x-ltw/2-4,cp.y-rPx-18,ltw+8,15,3);else ctx.rect(cp.x-ltw/2-4,cp.y-rPx-18,ltw+8,15);ctx.fill();ctx.fillStyle=cc;ctx.fillText(c.label,cp.x,cp.y-rPx-7);ctx.textAlign="left"}
                    }

                    // Geofence circle
                    if(behaviourObject&&behaviourObject.hasGeofence){
                        var gp=root.latLngToPixel(behaviourObject.geofenceLat,behaviourObject.geofenceLng),grPx=root.metersToPixels(behaviourObject.geofenceLat,behaviourObject.geofenceRadius)
                        var gCol=behaviourObject.inGeofence?"#22c55e":"#f59e0b"
                        ctx.save();ctx.setLineDash([8,5]);ctx.beginPath();ctx.arc(gp.x,gp.y,grPx,0,2*Math.PI);ctx.strokeStyle=gCol;ctx.lineWidth=2.5;ctx.stroke();ctx.fillStyle=gCol+"18";ctx.fill();ctx.restore()
                        ctx.font="bold 9px sans-serif";ctx.textAlign="center";var bTxt=behaviourObject.inGeofence?"● DENTRO":"○ FORA";var btw=ctx.measureText(bTxt).width
                        ctx.fillStyle=root.isDark?"rgba(0,0,0,0.75)":"rgba(255,255,255,0.88)";ctx.beginPath();if(ctx.roundRect)ctx.roundRect(gp.x-btw/2-5,gp.y-grPx-20,btw+10,16,4);else ctx.rect(gp.x-btw/2-5,gp.y-grPx-20,btw+10,16);ctx.fill()
                        ctx.fillStyle=gCol;ctx.fillText(bTxt,gp.x,gp.y-grPx-8);ctx.textAlign="left"
                    }

                    // GPS Trace
                    var tr=root.trace
                    if(tr.length>1){
                        ctx.beginPath();ctx.strokeStyle="#3b82f6";ctx.lineWidth=3;ctx.lineJoin="round";ctx.lineCap="round"
                        var p0=root.latLngToPixel(tr[0].lat,tr[0].lng);ctx.moveTo(p0.x,p0.y)
                        for(var ti=1;ti<tr.length;ti++){var tp=root.latLngToPixel(tr[ti].lat,tr[ti].lng);ctx.lineTo(tp.x,tp.y)}
                        ctx.stroke()
                        var pF=root.latLngToPixel(tr[0].lat,tr[0].lng);ctx.beginPath();ctx.arc(pF.x,pF.y,5,0,2*Math.PI);ctx.fillStyle="#22c55e";ctx.fill()
                        var pL=root.latLngToPixel(tr[tr.length-1].lat,tr[tr.length-1].lng);ctx.beginPath();ctx.arc(pL.x,pL.y,5,0,2*Math.PI);ctx.fillStyle="#ef4444";ctx.fill()
                    }

                    // Live breadcrumb trail
                    var lm=root.liveMarker
                    if(lm&&lm.breadcrumb&&lm.breadcrumb.length>1){
                        var crumb=lm.breadcrumb
                        for(var bi=1;bi<crumb.length;bi++){
                            var al=bi/crumb.length*0.55
                            var bA=root.latLngToPixel(crumb[bi-1].lat,crumb[bi-1].lng),bB=root.latLngToPixel(crumb[bi].lat,crumb[bi].lng)
                            ctx.beginPath();ctx.strokeStyle="rgba(16,185,129,"+al+")";ctx.lineWidth=2.5;ctx.moveTo(bA.x,bA.y);ctx.lineTo(bB.x,bB.y);ctx.stroke()
                        }
                    }

                    // Live marker (pulsating)
                    if(lm){
                        var lp=root.latLngToPixel(lm.lat,lm.lng)
                        for(var pi2=0;pi2<2;pi2++){var ph=(root.pulsePhase+pi2*0.5)%1.0,rr=10+ph*22,aa=(1-ph)*0.5;ctx.beginPath();ctx.arc(lp.x,lp.y,rr,0,2*Math.PI);ctx.strokeStyle="rgba(16,185,129,"+aa+")";ctx.lineWidth=2;ctx.stroke()}
                        ctx.shadowColor="rgba(0,0,0,0.45)";ctx.shadowBlur=6;ctx.beginPath();ctx.arc(lp.x,lp.y,9,0,2*Math.PI);ctx.fillStyle="#10b981";ctx.fill();ctx.strokeStyle="white";ctx.lineWidth=2;ctx.stroke();ctx.shadowBlur=0
                        ctx.beginPath();ctx.arc(lp.x,lp.y,3.5,0,2*Math.PI);ctx.fillStyle="white";ctx.fill()
                        if(lm.label){ctx.font="bold 10px sans-serif";var llw=ctx.measureText(lm.label).width;ctx.fillStyle=root.isDark?"rgba(0,0,0,0.75)":"rgba(255,255,255,0.9)";ctx.beginPath();if(ctx.roundRect)ctx.roundRect(lp.x+13,lp.y-11,llw+8,16,3);else ctx.rect(lp.x+13,lp.y-11,llw+8,16);ctx.fill();ctx.fillStyle=root.isDark?"#e8e8e8":"#111";ctx.fillText(lm.label,lp.x+17,lp.y+1)}
                    }

                    // Markers
                    for(var j=0;j<root.markers.length;j++){
                        var m=root.markers[j],mp=root.latLngToPixel(m.lat,m.lng)
                        var mc=m.type==="start"?"#22c55e":m.type==="end"?"#ef4444":"#6366f1"
                        var hov=(j===root.hoveredMarkerIdx),rad=hov?10:8
                        if(hov){ctx.beginPath();ctx.arc(mp.x,mp.y-11,16,0,2*Math.PI);ctx.fillStyle="rgba(99,102,241,0.18)";ctx.fill()}
                        ctx.shadowColor="rgba(0,0,0,0.35)";ctx.shadowBlur=5;ctx.beginPath();ctx.arc(mp.x,mp.y-11,rad,0,2*Math.PI);ctx.fillStyle=mc;ctx.fill();ctx.strokeStyle="white";ctx.lineWidth=1.5;ctx.stroke();ctx.shadowBlur=0
                        ctx.beginPath();ctx.arc(mp.x,mp.y-11,3,0,2*Math.PI);ctx.fillStyle="white";ctx.fill()
                        if(m.type==="marker"){ctx.font="bold 8px sans-serif";ctx.fillStyle="white";ctx.textAlign="center";ctx.fillText(j+1,mp.x,mp.y-7);ctx.textAlign="left"}
                        var tw2=hov?6:5;ctx.beginPath();ctx.moveTo(mp.x-tw2,mp.y-5);ctx.lineTo(mp.x,mp.y);ctx.lineTo(mp.x+tw2,mp.y-5);ctx.closePath();ctx.fillStyle=mc;ctx.fill()
                        if(m.label){ctx.font="bold 10px sans-serif";var lw=ctx.measureText(m.label).width;ctx.fillStyle=root.isDark?"rgba(20,20,20,0.75)":"rgba(255,255,255,0.88)";ctx.beginPath();if(ctx.roundRect)ctx.roundRect(mp.x+12,mp.y-25,lw+8,16,3);else ctx.rect(mp.x+12,mp.y-25,lw+8,16);ctx.fill();ctx.fillStyle=root.isDark?"#e8e8e8":"#111";ctx.fillText(m.label,mp.x+16,mp.y-13)}
                        if(hov&&m.type==="marker"){ctx.font="9px sans-serif";var hint="⌦ RMB: remover";var htw=ctx.measureText(hint).width;ctx.fillStyle=root.isDark?"rgba(20,20,20,0.82)":"rgba(255,255,255,0.90)";ctx.beginPath();if(ctx.roundRect)ctx.roundRect(mp.x-htw/2-5,mp.y-38,htw+10,15,3);else ctx.rect(mp.x-htw/2-5,mp.y-38,htw+10,15);ctx.fill();ctx.fillStyle=root.isDark?"#aaa":"#555";ctx.textAlign="center";ctx.fillText(hint,mp.x,mp.y-27);ctx.textAlign="left"}
                    }

                    // Measure tool
                    if(root.measureMode){
                        var pts=root.measurePts
                        for(var pi3=0;pi3<pts.length;pi3++){var pp=root.latLngToPixel(pts[pi3].lat,pts[pi3].lng);ctx.beginPath();ctx.arc(pp.x,pp.y,6,0,2*Math.PI);ctx.fillStyle="#f59e0b";ctx.fill();ctx.strokeStyle="white";ctx.lineWidth=1.5;ctx.stroke()}
                        var lineEnd=pts.length===2?root.latLngToPixel(pts[1].lat,pts[1].lng):(pts.length===1?Qt.point(mapArea.mouseX,mapArea.mouseY):null)
                        if(lineEnd&&pts.length>=1){
                            var ls=root.latLngToPixel(pts[0].lat,pts[0].lng);ctx.save();ctx.setLineDash([6,4]);ctx.beginPath();ctx.moveTo(ls.x,ls.y);ctx.lineTo(lineEnd.x,lineEnd.y);ctx.strokeStyle="#f59e0b";ctx.lineWidth=2;ctx.stroke();ctx.restore()
                            var la2=pts.length===2?pts[1].lat:root.measureCurLat,ln2=pts.length===2?pts[1].lng:root.measureCurLng
                            var dist=root.haversineKm(pts[0].lat,pts[0].lng,la2,ln2),dTxt=root.fmtDist(dist)
                            var mX=(ls.x+lineEnd.x)/2,mY=(ls.y+lineEnd.y)/2-12;ctx.font="bold 11px sans-serif";var dtw=ctx.measureText(dTxt).width
                            ctx.fillStyle=root.isDark?"rgba(0,0,0,0.82)":"rgba(255,255,255,0.92)";ctx.beginPath();if(ctx.roundRect)ctx.roundRect(mX-dtw/2-6,mY-12,dtw+12,20,5);else ctx.rect(mX-dtw/2-6,mY-12,dtw+12,20);ctx.fill()
                            ctx.fillStyle="#f59e0b";ctx.textAlign="center";ctx.fillText(dTxt,mX,mY+4);ctx.textAlign="left"
                        }
                    }

                    // Trace mode ghost cursor + rubber-band line
                    if(root.addTraceMode&&mapArea.containsMouse){
                        var tmx=mapArea.mouseX,tmy=mapArea.mouseY
                        if(root.trace.length>0){var lastPt=root.trace[root.trace.length-1],lastPx=root.latLngToPixel(lastPt.lat,lastPt.lng);ctx.save();ctx.setLineDash([4,3]);ctx.beginPath();ctx.moveTo(lastPx.x,lastPx.y);ctx.lineTo(tmx,tmy);ctx.strokeStyle="rgba(139,92,246,0.7)";ctx.lineWidth=2;ctx.stroke();ctx.restore()}
                        ctx.beginPath();ctx.arc(tmx,tmy,5,0,2*Math.PI);ctx.fillStyle="#8b5cf6";ctx.fill();ctx.strokeStyle="white";ctx.lineWidth=1.5;ctx.stroke()
                    }

                    // Circle mode ghost cursor
                    if(root.addCircleMode&&mapArea.containsMouse){
                        var cmx=mapArea.mouseX,cmy=mapArea.mouseY
                        ctx.beginPath();ctx.arc(cmx,cmy,6,0,2*Math.PI);ctx.fillStyle="#3b82f6";ctx.fill();ctx.strokeStyle="white";ctx.lineWidth=1.5;ctx.stroke()
                        ctx.beginPath();ctx.strokeStyle="rgba(59,130,246,0.45)";ctx.lineWidth=1;ctx.moveTo(cmx-12,cmy);ctx.lineTo(cmx+12,cmy);ctx.moveTo(cmx,cmy-12);ctx.lineTo(cmx,cmy+12);ctx.stroke()
                    }

                    // Add-marker ghost cursor + coord tooltip
                    if(root.addMarkerMode&&mapArea.containsMouse){
                        var amx=mapArea.mouseX,amy=mapArea.mouseY
                        ctx.beginPath();ctx.arc(amx,amy-11,8,0,2*Math.PI);ctx.fillStyle="rgba(34,197,94,0.42)";ctx.fill();ctx.strokeStyle="#22c55e";ctx.lineWidth=2;ctx.stroke()
                        ctx.beginPath();ctx.moveTo(amx-5,amy-5);ctx.lineTo(amx,amy);ctx.lineTo(amx+5,amy-5);ctx.closePath();ctx.fillStyle="rgba(34,197,94,0.42)";ctx.fill()
                        var ac=root.pixelToLatLng(amx,amy),tip=ac.x.toFixed(5)+",  "+ac.y.toFixed(5);ctx.font="10px Consolas, monospace";var tw3=ctx.measureText(tip).width,tx3=Math.min(amx+14,width-tw3-12),ty3=Math.min(amy+8,height-24)
                        ctx.fillStyle=root.isDark?"rgba(10,10,10,0.82)":"rgba(255,255,255,0.93)";ctx.beginPath();if(ctx.roundRect)ctx.roundRect(tx3-4,ty3,tw3+8,18,4);else ctx.rect(tx3-4,ty3,tw3+8,18);ctx.fill();ctx.fillStyle=root.isDark?"#ddd":"#222";ctx.fillText(tip,tx3,ty3+13)
                    }
                }
            }

            // Scale bar
            Item { anchors{left:parent.left;bottom:parent.bottom;leftMargin:10;bottomMargin:6}
                Text {
                    id: scaleLbl
                    anchors { horizontalCenter: scaleRect.horizontalCenter; bottom: scaleRect.top; bottomMargin: 2 }
                    text: root.scaleInfo ? root.scaleInfo.label : ""
                    color: root.isDark ? "white" : "#222"
                    font.pixelSize: 9
                    style: Text.Outline
                    styleColor: root.isDark ? "#111" : "white"
                }
                Rectangle{id:scaleRect;anchors{bottom:parent.bottom;left:parent.left;bottomMargin:12}width:root.scaleInfo?Math.max(20,Math.min(root.scaleInfo.px,120)):60;height:3;color:root.isDark?"white":"#333"
                    Rectangle{width:1;height:7;color:parent.color;anchors{left:parent.left;verticalCenter:parent.verticalCenter}}
                    Rectangle{width:1;height:7;color:parent.color;anchors{right:parent.right;verticalCenter:parent.verticalCenter}}}
            }

            // Attribution
            Text {
                anchors { right: parent.right; bottom: parent.bottom; rightMargin: 5; bottomMargin: 3 }
                text: root.attrib()
                color: root.isDark ? "#8cc8c8c8" : "#a63c3c3c"
                font.pixelSize: 8
            }

            // Mode banners
            Rectangle { anchors{top:parent.top;horizontalCenter:parent.horizontalCenter;topMargin:8} visible:root.addMarkerMode;width:addBTxt.width+24;height:26;radius:13;color:"#22c55e"
                Text{id:addBTxt;anchors.centerIn:parent;text:"Clique para posicionar marcador";color:"white";font.pixelSize:11;font.bold:true} }
            Rectangle { anchors{top:parent.top;horizontalCenter:parent.horizontalCenter;topMargin:8} visible:root.addCircleMode;width:cBTxt.width+24;height:26;radius:13;color:"#3b82f6"
                Text{id:cBTxt;anchors.centerIn:parent;text:"Clique para posicionar o centro do círculo";color:"white";font.pixelSize:11;font.bold:true} }
            Rectangle { anchors{top:parent.top;horizontalCenter:parent.horizontalCenter;topMargin:8} visible:root.addTraceMode;width:tBTxt.width+24;height:26;radius:13;color:"#8b5cf6"
                Text{id:tBTxt;anchors.centerIn:parent;text:"Clique para adicionar ponto de trace";color:"white";font.pixelSize:11;font.bold:true} }
            Rectangle { anchors{top:parent.top;horizontalCenter:parent.horizontalCenter;topMargin:8} visible:root.measureMode;width:mBTxt.width+24;height:26;radius:13;color:"#f59e0b"
                Text{id:mBTxt;anchors.centerIn:parent;color:"white";font.pixelSize:11;font.bold:true
                    text:root.measurePts.length===0?"Clique ponto A":root.measurePts.length===1?"Clique ponto B":"Clique para nova medição · ESC limpa"} }

            // Trace mode undo/clear bar (floating, bottom right)
            Row {
                anchors { right: parent.right; bottom: parent.bottom; rightMargin: 10; bottomMargin: 8 }
                spacing: 6; visible: root.addTraceMode
                Rectangle {
                    width: 64; height: 24; radius: 5
                    color: "#d88b5cf6"
                    Text { anchors.centerIn: parent; text: "⎌ Desfazer"; color: "white"; font.pixelSize: 9; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: if(behaviourObject) behaviourObject.removeLastTracePoint() }
                }
                Rectangle {
                    width: 56; height: 24; radius: 5
                    color: "#bf505050"
                    Text { anchors.centerIn: parent; text: "Limpar"; color: "white"; font.pixelSize: 9; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: if(behaviourObject) behaviourObject.clearTrace() }
                }
                Rectangle {
                    width: 58; height: 24; radius: 5
                    color: "#d88b5cf6"
                    Text { anchors.centerIn: parent; text: "✓ Concluir"; color: "white"; font.pixelSize: 9; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: root.activeMode = "" }
                }
            }

            // ── Mouse area ─────────────────────────────────────────────────────
            MouseArea {
                id: mapArea; anchors.fill: parent; hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: (root.addMarkerMode||root.addCircleMode||root.addTraceMode||root.measureMode) ? Qt.CrossCursor
                           : root.isDragging            ? Qt.ClosedHandCursor
                           : root.hoveredMarkerIdx >= 0 ? Qt.PointingHandCursor
                           :                              Qt.OpenHandCursor

                onPressed: function(mouse) {
                    mapClip.forceActiveFocus()
                    styleDropdown.visible=false
                    if(mouse.button!==Qt.LeftButton)return
                    root.dragStartX=mouse.x;root.dragStartY=mouse.y
                    root.dragStartLat=root.centerLat;root.dragStartLng=root.centerLng
                    root.isDragging=false;markerPopup.visible=false;circlePopup.visible=false
                }

                onPositionChanged: function(mouse) {
                    var c=root.pixelToLatLng(mouse.x,mouse.y); root.hoverLat=c.x; root.hoverLng=c.y
                    root.measureCurLat=c.x; root.measureCurLng=c.y
                    if(root.addMarkerMode||root.addCircleMode||root.addTraceMode||root.measureMode){overlayCanvas.requestPaint();return}
                    var prev=root.hoveredMarkerIdx; root.hoveredMarkerIdx=root.nearestMarker(mouse.x,mouse.y,14)
                    if(root.hoveredMarkerIdx!==prev)overlayCanvas.requestPaint()
                    if(!pressed||mouse.buttons!==Qt.LeftButton)return
                    var dx=mouse.x-root.dragStartX,dy=mouse.y-root.dragStartY
                    if(!root.isDragging&&(Math.abs(dx)>3||Math.abs(dy)>3))root.isDragging=true
                    if(root.isDragging){
                        tileLayer.panBy(dx,dy)
                        var ts=256,sc=Math.pow(2,root.zoom)*ts
                        root.centerLng=root.dragStartLng-dx/sc*360
                        var cPy=(1-Math.log(Math.tan(Math.PI/4+root.dragStartLat*Math.PI/360))/Math.PI)/2
                        var nPy=Math.max(0.001,Math.min(0.999,cPy-dy/sc))
                        root.centerLat=180/Math.PI*(2*Math.atan(Math.exp((1-2*nPy)*Math.PI))-Math.PI/2)
                        overlayCanvas.requestPaint()
                    }
                }

                onReleased: function(mouse) {
                    if(mouse.button!==Qt.LeftButton)return
                    if(root.isDragging){tileLayer.fullRefresh();overlayCanvas.requestPaint()}
                    else {
                        var coord=root.pixelToLatLng(mouse.x,mouse.y)
                        if(root.measureMode){
                            root.measurePts=root.measurePts.length<2?root.measurePts.concat([{lat:coord.x,lng:coord.y}]):[{lat:coord.x,lng:coord.y}]
                            overlayCanvas.requestPaint()
                        } else if(root.addTraceMode) {
                            if(behaviourObject)behaviourObject.addTracePoint(coord.x,coord.y)
                        } else if(root.addCircleMode) {
                            // Show circle popup at root coordinates
                            circlePopup.pendingLat=coord.x; circlePopup.pendingLng=coord.y
                            circlePopup.asGeofence=false; radiusIn.text="500"; circleLblIn.text=""
                            var pos=mapClip.mapToItem(root,mouse.x,mouse.y)
                            circlePopup.x=Math.min(pos.x+8,root.width-circlePopup.width-8)
                            circlePopup.y=Math.min(pos.y+8,root.height-circlePopup.height-8)
                            circlePopup.visible=true
                        } else if(root.addMarkerMode) {
                            markerPopup.pendingLat=coord.x; markerPopup.pendingLng=coord.y; lblIn.text=""
                            var pos2=mapClip.mapToItem(root,mouse.x,mouse.y)
                            markerPopup.x=Math.min(pos2.x+8,root.width-markerPopup.width-8)
                            markerPopup.y=Math.min(pos2.y+8,root.height-markerPopup.height-8)
                            markerPopup.visible=true; lblIn.forceActiveFocus()
                        } else if(behaviourObject) {
                            behaviourObject.mapClicked(coord.x,coord.y)
                        }
                    }
                    root.isDragging=false
                }

                onClicked: function(mouse) {
                    if(mouse.button!==Qt.RightButton)return
                    var idx=root.nearestMarker(mouse.x,mouse.y,16)
                    if(idx>=0&&behaviourObject&&root.markers[idx]&&root.markers[idx].type==="marker")behaviourObject.removeMarkerAt(idx)
                }

                onWheel: function(wheel) {
                    var delta=wheel.angleDelta.y>0?1:-1,nz=Math.max(1,Math.min(19,root.zoom+delta))
                    if(nz===root.zoom)return
                    var ns=Math.pow(2,nz)*256,cc=root.pixelToLatLng(wheel.x,wheel.y)
                    root.centerLng=cc.y-(wheel.x-mapClip.width/2)/ns*360
                    var cpy=(1-Math.log(Math.tan(Math.PI/4+cc.x*Math.PI/360))/Math.PI)/2
                    var ncpy=Math.max(0.001,Math.min(0.999,cpy-(wheel.y-mapClip.height/2)/ns))
                    root.centerLat=180/Math.PI*(2*Math.atan(Math.exp((1-2*ncpy)*Math.PI))-Math.PI/2)
                    root.zoom=nz; tileLayer.fullRefresh(); overlayCanvas.requestPaint()
                }

                onExited: { root.hoveredMarkerIdx=-1; overlayCanvas.requestPaint() }
            }
        }

        // ── Status bar ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 22; color: ThemeManager.surfaceColor
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: ThemeManager.borderColor }
            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                spacing: 10
                Text { text: (behaviourObject?behaviourObject.markerCount:0)+" pin"; color:ThemeManager.textSecondaryColor;font.pixelSize:10 }
                Text { text: (behaviourObject?behaviourObject.traceLength:0)+" trace"; color:ThemeManager.textSecondaryColor;font.pixelSize:10 }
                Text { text: (behaviourObject?behaviourObject.circleCount:0)+" circ"; color:ThemeManager.textSecondaryColor;font.pixelSize:10 }
                Text { visible:root.liveMarker!==null;text:"● Live";color:"#10b981";font.pixelSize:10;font.bold:true }
                Text { visible:behaviourObject&&behaviourObject.hasGeofence;text:behaviourObject&&behaviourObject.inGeofence?"⬤ DENTRO":"○ FORA";color:behaviourObject&&behaviourObject.inGeofence?"#22c55e":"#f59e0b";font.pixelSize:10;font.bold:true }
                Item { Layout.fillWidth: true }
                Text { text:root.hoverLat.toFixed(5)+",  "+root.hoverLng.toFixed(5);color:ThemeManager.textSecondaryColor;font.pixelSize:10;font.family:"Consolas, monospace" }
            }
        }
    }
}
