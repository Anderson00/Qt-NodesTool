import QtQuick 2.14
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Material 2.0
import Qaterial 1.0 as Qaterial
import App.Theme 1.0

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

    Timer {
        id: randomGenerator
        repeat: true
        interval: intervalSlider.value

        onTriggered: {
            let newNumber = behaviourObject.genNewNumber(minNumberSlider.value, maxNumberSlider.value);
            currentValueLabel.text = newNumber.toFixed(2);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        NewButton {
            id: btStart
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            variant: "outlined"
            text: randomGenerator.running? "Stop" : "Start"
            backgroundColor: randomGenerator.running ? ThemeManager.dangerColor : ThemeManager.primaryColor

            onClicked: {
                if(randomGenerator.running){
                    randomGenerator.stop()
                }else{
                    randomGenerator.start()
                }
            }
        }

        CustomSlider {
            id: minNumberSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            from: 0
            to: 5000
            textColor: ThemeManager.textColor
            color: ThemeManager.primaryColor
        }

        CustomSlider {
            id: maxNumberSlider
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            from: minNumberSlider.value
            to: minNumberSlider.value+5000
            textColor: ThemeManager.textColor
            color: ThemeManager.primaryColor
        }

        CustomSlider {
            id: intervalSlider
            Layout.fillWidth: true
            from: 50
            to: 5000
            prefix: "ms"
            height: 40
            textColor: ThemeManager.textColor
            color: ThemeManager.primaryColor
        }

        Label {
            id: currentValueLabel
            font.pixelSize: 20
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            text: "0"
            color: ThemeManager.textColor
        }
    }
}
