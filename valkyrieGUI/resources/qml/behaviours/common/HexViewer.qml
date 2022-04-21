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
            console.log(behaviourObject)
            //behaviourObject.contentHeight = 200

            console.log(behaviourObject.getInputsMethodSignature())
            console.log(behaviourObject.getOutputsMethodSignature())

            behaviourObject.input('Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source. Lorem Ipsum comes from sections 1.10.32 and 1.10.33 of "de Finibus Bonorum et Malorum" (The Extremes of Good and Evil) by Cicero, written in 45 BC. This book is a treatise on the theory of ethics, very popular during the Renaissance. The first line of Lorem Ipsum, "Lorem ipsum dolor sit amet..", comes from a line in section 1.10.32.')
        }
    }

    Connections {
        target: behaviourObject

        function onViewOutput(obj){
            listView.model = obj
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Label {
                text: 'Offset'
                font.pixelSize: 10
            }

            Repeater {
                model: behaviourObject.hexColumns
                Label {
                    text: '0'+Number(index).toString(16).toUpperCase()
                    font.pixelSize: 10
                }
            }

            Label {
                text: 'ASCII'
                font.pixelSize: 10
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 12
            clip: true

            delegate: RowLayout {

                property int indexOF: index

                Label {
                    id: ofsset

                    text: modelData.offset
                    font.pixelSize: 8
                }

                Repeater {
                    model: listView.model[index].bytes
                    Label {
                        text: listView.model[indexOF].bytes[index]
                        font.pixelSize: 8
                    }
                }

                Label {
                    text: hex_to_ascii(listView.model[index].bytes.join(''))
                    font.pixelSize: 8
                }
            }

    //        delegate: RowLayout{
    //            Label {
    //                id: ofsset

    //                text: 'Offset'
    //                font.pixelSize: index === 0? 12 : 8
    //            }

    //            Repeater {
    //                model: 16
    //                Label {
    //                    text: '0'+Number(index).toString(16).toUpperCase()
    //                    font.pixelSize: index === 0? 12 : 8
    //                }
    //            }

    //            Label {
    //                text: 'ASCII'
    //                font.pixelSize: index === 0? 12 : 8
    //            }
    //        }
        }

    }
}
