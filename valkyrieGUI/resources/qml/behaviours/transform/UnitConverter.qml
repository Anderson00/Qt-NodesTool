import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property string localCategory: "length"
    property string localFrom:     "m"
    property string localTo:       "km"
    property real   localValue:    0.0
    property real   localResult:   0.0
    property string localResultUnit: "km"

    property var categories: ["length", "mass", "temperature", "speed"]

    function unitsFor(cat) {
        if (!behaviourObject) {
            if (cat === "length")      return ["m","km","cm","mm","ft","in","mi","yd"]
            if (cat === "mass")        return ["kg","g","lb","oz","t"]
            if (cat === "temperature") return ["C","F","K"]
            if (cat === "speed")       return ["m/s","km/h","mph","knot"]
            return []
        }
        return behaviourObject.unitsForCategory(cat)
    }

    function triggerConvert() {
        if (behaviourObject) behaviourObject.convert(localValue)
    }

    Connections {
        target: behaviourObject
        function onInternalResult(converted, unit) {
            localResult     = converted
            localResultUnit = unit
        }
        function onInternalConversionChanged(from, to, category) {
            localFrom     = from
            localTo       = to
            localCategory = category
        }
        function onFromUnitChanged() {
            if (behaviourObject) localFrom = behaviourObject.fromUnit
        }
        function onToUnitChanged() {
            if (behaviourObject) localTo = behaviourObject.toUnit
        }
        function onCategoryChanged() {
            if (behaviourObject) localCategory = behaviourObject.category
        }
    }

    Component.onCompleted: {
        if (behaviourObject) {
            localCategory = behaviourObject.category
            localFrom     = behaviourObject.fromUnit
            localTo       = behaviourObject.toUnit
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // -- Header --
        Text {
            text: qsTr("Unit Converter")
            font.pixelSize: 10
            font.bold: true
            color: ThemeManager.textColor
        }

        // -- Category selector --
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Category")
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 58
            }

            CustomComboBox {
                id: categoryCombo
                Layout.fillWidth: true
                model: root.categories
                currentIndex: root.categories.indexOf(root.localCategory)
                onCurrentTextChanged: {
                    if (currentText === root.localCategory) return
                    root.localCategory = currentText
                    var units = root.unitsFor(currentText)
                    root.localFrom = units.length > 0 ? units[0] : ""
                    root.localTo   = units.length > 1 ? units[1] : (units.length > 0 ? units[0] : "")
                    if (behaviourObject)
                        behaviourObject.setConversion(root.localFrom, root.localTo)
                }
            }
        }

        // -- From / Swap / To row --
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("From")
                    font.pixelSize: 8
                    color: ThemeManager.textSecondaryColor
                }

                CustomComboBox {
                    id: fromCombo
                    Layout.fillWidth: true
                    model: root.unitsFor(root.localCategory)
                    currentIndex: Math.max(0, model.indexOf(root.localFrom))
                    onCurrentTextChanged: {
                        if (currentText === root.localFrom) return
                        root.localFrom = currentText
                        if (behaviourObject)
                            behaviourObject.setConversion(root.localFrom, root.localTo)
                        root.triggerConvert()
                    }
                }
            }

            // Swap button
            NewButton {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignBottom
                variant: "outlined"
                iconSource: Icons.arrowLeftRight
                onClicked: {
                    var tmp = root.localFrom
                    root.localFrom = root.localTo
                    root.localTo   = tmp
                    if (behaviourObject)
                        behaviourObject.setConversion(root.localFrom, root.localTo)
                    root.triggerConvert()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("To")
                    font.pixelSize: 8
                    color: ThemeManager.textSecondaryColor
                }

                CustomComboBox {
                    id: toCombo
                    Layout.fillWidth: true
                    model: root.unitsFor(root.localCategory)
                    currentIndex: Math.max(0, model.indexOf(root.localTo))
                    onCurrentTextChanged: {
                        if (currentText === root.localTo) return
                        root.localTo = currentText
                        if (behaviourObject)
                            behaviourObject.setConversion(root.localFrom, root.localTo)
                        root.triggerConvert()
                    }
                }
            }
        }

        // -- Input value --
        NumericInputField {
            Layout.fillWidth: true
            implicitHeight: 36
            label: qsTr("Value (") + root.localFrom + ")"
            value: root.localValue
            from: -1e15
            to:    1e15
            stepSize: 1.0
            decimals: 6
            onValueModified: function(newValue) {
                root.localValue = newValue
                if (behaviourObject) behaviourObject.convert(newValue)
            }
        }

        // -- Result display --
        Rectangle {
            Layout.fillWidth: true
            height: 52
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.25)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.localResult.toFixed(6)
                    font.pixelSize: 18
                    font.bold: true
                    font.family: "Consolas, monospace"
                    color: ThemeManager.primaryColor
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.localFrom + "  →  " + root.localResultUnit
                    font.pixelSize: 9
                    color: ThemeManager.textSecondaryColor
                }
            }
        }
    }
}
