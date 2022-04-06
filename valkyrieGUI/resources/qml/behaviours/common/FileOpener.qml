import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0

Item {
    anchors.fill: parent

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
            Layout.fillWidth: true
        }

        Button {
            id: btOpen
            text: "Open"
            font.pixelSize: 12
            Layout.rightMargin: 8
        }
    }
}
