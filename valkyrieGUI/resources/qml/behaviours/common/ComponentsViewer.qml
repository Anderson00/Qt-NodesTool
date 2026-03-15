import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0

import '../../components'

Item {
    anchors.fill: parent

    property var behaviourObject

    Component.onCompleted: {
        debounce.start();
    }

    Timer {
        id: debounce
        repeat: false

        interval: 50

        onTriggered: {

        }
    }

    ColumnLayout{
        width: parent.width
        anchors{
            top: parent.top
            left: parent.left
            right: parent.right

            leftMargin: 8
            rightMargin: 16
            topMargin: 8
        }

        IconButton {
            iconSource: "qrc:/icons/play"
        }

        NewButton {
            iconSource: "qrc:/icons/play"
            text: "testando"
        }
        
        NewButton {
            iconSource: "qrc:/icons/clo"
            text: "testando"
            iconSize: 12
        }
    }
}
