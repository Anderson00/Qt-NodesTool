import QtQuick 2.15
import QtQuick.Window 2.15
import App.Theme 1.0

Item {
    id: root

    property real cameraX:      5000
    property real cameraY:      5000
    property real cameraWidth:  1920
    property real cameraHeight: 1200
    property var  nodesModel:   null
    property bool isPlaying:    false

    // Super Sampling Factor: 1.0 = screen native, > 1.0 = extra sharp
    // Limitado a 4.0 para segurança (evitar crash de GPU em valores extremos)
    property real superSampling: 1.0
    readonly property real _safeSS: Math.min(superSampling, 4.0)

    readonly property real s: root.cameraWidth > 0 ? width / root.cameraWidth : 1.0

    Rectangle { 
        anchors.fill: parent
        color: Qt.darker(ThemeManager.backgroundColor, 1.15) 
    }

    Item {
        id: worldContainer
        width:  10000
        height: 10000
        x: -root.cameraX * root.s
        y: -root.cameraY * root.s

        transform: Scale {
            xScale: root.s;
            yScale:  root.s
            origin.x: 0; origin.y: 0
        }

        Repeater {
            model: root.nodesModel

            delegate: Item {
                property var obj: model ? model.object : null
                x:      obj ? obj.x      : 0
                y:      obj ? obj.y      : 0
                width:  obj ? obj.width  : 0
                height: obj ? obj.height : 0
                
                visible: (obj && obj.qmlBodyUrl !== "") && (root.isPlaying ? (!!model.isVisualization) : (!model.isVisualization))

                // layer.enabled: true
                // layer.smooth:  true
                // layer.textureSize: Qt.size(
                //     width  * root.s * Screen.devicePixelRatio * root._safeSS,
                //     height * root.s * Screen.devicePixelRatio * root._safeSS
                // )

                // Moldura para o nó na visualização
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.4)
                    border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.2)
                    border.width: 1 / root.s
                    radius: 4
                }

                Loader {
                    id: bodyLoader
                    anchors.fill: parent
                    property var behaviourObject: parent.obj
                    clip: true
                    source: (parent.obj && parent.obj.qmlBodyUrl !== "") ? parent.obj.qmlBodyUrl : ""
                    onLoaded: {
                        if (item && item.hasOwnProperty("behaviourObject"))
                            item.behaviourObject = parent.obj
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: "Câmera não definida\nou nenhum nó tem corpo visual"
        horizontalAlignment: Text.AlignHCenter
        color: "#444444"; font.pixelSize: 10
        visible: {
            if (!root.nodesModel) return true
            for (var i = 0; i < root.nodesModel.count; i++) {
                var o = root.nodesModel.get(i).object
                if (o && o.qmlBodyUrl !== "") return false
            }
            return true
        }
    }
}
