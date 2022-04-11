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
            console.log(behaviourObject)
            //behaviourObject.contentHeight = 200

            console.log(behaviourObject.getInputsMethodSignature())
            console.log(behaviourObject.getOutputsMethodSignature())
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

        RowLayout {
            Layout.fillWidth: true

            CustomTextField {
                id: rootPath
                placeholderText: "Root (default: .)"
                Layout.fillWidth: true
            }

            CustomTextField {
                id: filter
                placeholderText: "Filter ex: *.exe"
                Layout.fillWidth: true
            }

            Button {
                id: btOpen
                text: ""
                icon.source: 'qrc:/Qaterial/Icons/folder-open'
                font.pixelSize: 12
                Layout.rightMargin: 8

                onClicked: {
                    let rootText = rootPath.text ?? '.'
                    fileUrl.text = behaviourObject.chooseFile(rootText, filter.text)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 16

            CustomTextField {
                id: fileUrl
                placeholderText: "Path"
                Layout.fillWidth: true
            }            
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.rightMargin: 16

            CustomTextField {
                id: fileName
                placeholderText: "Name"
                enabled: false
                Layout.fillWidth: true
            }

            CustomTextField {
                id: fileSize
                enabled: false
                placeholderText: "Size"
                //Layout.fillWidth: true
                Layout.preferredWidth: 50
            }
        }
    }
}
