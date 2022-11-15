import QtQuick 2.14
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import Qt.labs.qmlmodels 1.0

import '../../components'

//import TableModel 1.0

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

        Rectangle{
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: '#222'
            TableView {
                id: tableView
                anchors.fill: parent
                rowSpacing: 0
                columnSpacing: 1
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    visible: true

                    contentItem: Rectangle {
                        width: 100
                        implicitHeight:4
                        radius: implicitHeight/2
                        //color: Material.accentColor
                    }
                }

                model: TableModel {
                    TableModelColumn { display: "pid" }
                    TableModelColumn { display: "processName" }

                    // Each row is one type of fruit that can be ordered
                    rows: [
                        {
                            // Each property is one cell/column.
                            pid: 159647,
                            processName: "google chrome"
                        },
                        {
                            // Each property is one cell/column.
                            pid: 159697,
                            processName: "google"
                        },
                        {
                            // Each property is one cell/column.
                            pid: 159698,
                            processName: "firefox"
                        }
                    ]
                }

                delegate: DelegateChooser {
                    DelegateChoice {
                        column: 0
                        delegate: Rectangle {
                            width: lbPid.width
                            height: lbPid.height
                            color: "#222"
                            Label {
                                id: lbPid
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.display

                            }
                        }
                    }
                    DelegateChoice {
                        column: 1

                        delegate: Rectangle {
                            width: root.width
                            height: lbPName.height
                            color: "#222"
                            Label {
                                id: lbPName
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.display
                            }
                        }
                    }
                }
            }
        }
    }
}
