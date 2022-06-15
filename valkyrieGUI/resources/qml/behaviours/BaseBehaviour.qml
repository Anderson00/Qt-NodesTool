import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0

import '../components'

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
}
