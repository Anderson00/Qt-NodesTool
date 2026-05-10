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
    property real superSampling: 1.0

    readonly property real s: root.cameraWidth > 0 ? width / root.cameraWidth : 1.0

    Rectangle { anchors.fill: parent; color: "#111111" }

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
                
                // Em modo "Playing" (Fullscreen/External), mostramos apenas nós marcados para visualização.
                // Fora dele (no preview da janelinha), mostramos apenas os que NÃO são visualização.
                visible: (obj && obj.qmlBodyUrl !== "") && (root.isPlaying ? (!!model.isVisualization) : (!model.isVisualization))

                // Super Sampling: Força o nó a renderizar na resolução real da tela (escala aplicada)
                // Multiplicamos pelo devicePixelRatio para garantir nitidez em telas High-DPI (4K/Retina)
                layer.enabled: true
                layer.smooth:  true
                layer.textureSize: Qt.size(
                    width  * root.s * Screen.devicePixelRatio * root.superSampling,
                    height * root.s * Screen.devicePixelRatio * root.superSampling
                )

                // Moldura para o nó na visualização (substitui o crome do editor)
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.15, 0.15, 0.15, 0.4)
                    border.color: Qt.rgba(1, 1, 1, 0.15)
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
