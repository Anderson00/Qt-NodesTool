import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0

Item {
    anchors.fill: parent

    property var behaviourObject

    Component.onCompleted: {
        debounce.start()
    }

    Timer {
        id: debounce
        repeat: false

        interval: 50

        onTriggered: {
            console.log(behaviourObject)
        }
    }

    RowLayout {
        width: parent.width
        anchors{
            top: parent.top
            left: parent.left
            right: parent.right

            leftMargin: 8
            rightMargin: 8
            topMargin: 8
        }

        TextField {
            id: fileUrl
            placeholderText: "Path"
            enabled: false
            Layout.fillWidth: true
        }

        Button {
            id: btOpen
            text: ""
            icon.source: 'qrc:/Qaterial/Icons/folder-open'
            font.pixelSize: 12
            Layout.rightMargin: 8
        }
    }
}
