import QtQuick 2.15
import QtQuick.Window 2.15
import App.Theme 1.0
import "../components/viewport"

Window {
    id: root
    
    property real cameraX:      5000
    property real cameraY:      5000
    property real cameraWidth:  800
    property real cameraHeight: 450
    property var  nodesModel:   null
    property bool isPlaying:    false
    
    title: qsTr("Valkyrie — External Visualization")
    width:  1280
    height: 720
    minimumWidth: 400
    minimumHeight: 300
    color:  "#111111"
    
    VisualizationPreview {
        anchors.fill: parent
        
        cameraX:      root.cameraX
        cameraY:      root.cameraY
        cameraWidth:  root.cameraWidth
        cameraHeight: root.cameraHeight
        nodesModel:   root.nodesModel
        isPlaying:    root.isPlaying
        
        // Em janela externa, aumentamos levemente o super-sampling para máxima nitidez
        superSampling: 1.2 
    }

    // Atalho ESC para fechar a janela externa
    Shortcut {
        sequence: "Escape"
        onActivated: root.close()
    }
}

