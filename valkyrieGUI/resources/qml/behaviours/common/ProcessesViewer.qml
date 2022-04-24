import QtQuick 2.14
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0

import '../../components'

Item {
    anchors.fill: parent

    property var behaviourObject

    Component.onCompleted: {
        debounce.start();
    }

    function hex_to_ascii(str1){
        var hex  = str1.toString();
        var str = '';
        for (var n = 0; n < hex.length; n += 2) {
            str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));
        }
        return str;
    }

    Timer {
        id: debounce
        repeat: false

        interval: 50

        onTriggered: {

        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 12
            clip: true

            model: 12

            delegate: RowLayout {

                Label {
                    text: 'google chrome'
                    font.pixelSize: 8
                }

                Label {
                    id: ofsset

                    text: '12'
                    font.pixelSize: 8
                }
            }
        }

    }
}
