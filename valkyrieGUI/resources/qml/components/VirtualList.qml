import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// VirtualList — high-performance ListView wrapper for large datasets.
// Renders only visible items + buffer zone. Exposes same-slot API
// as ListView for simple drop-in usage.
//
// Usage:
//   VirtualList {
//       model: myLargeArray
//       itemHeight: 48
//       delegate: Rectangle {
//           width: VirtualList.view.width
//           height: 48
//           Text { text: modelData.name }
//       }
//   }
Item {
    id: root

    // Public API
    property var  model:          []
    property Component delegate:  null
    property int  itemHeight:     48
    property int  bufferItems:    8       // extra items to render above/below viewport
    property bool showScrollBar:  true
    property color scrollBarColor: ThemeManager.primaryColor

    // Forwarded ListView properties
    property int  spacing:        0
    property bool clip:           true

    signal itemClicked(int index, var item)

    implicitWidth:  200
    implicitHeight: 400

    ListView {
        id: lv
        anchors.fill: parent
        model: root.model
        delegate: root.delegate
        spacing: root.spacing
        clip: root.clip
        cacheBuffer: root.itemHeight * root.bufferItems
        boundsBehavior: Flickable.StopAtBounds
        maximumFlickVelocity: 3000
        flickDeceleration: 1500

        ScrollBar.vertical: ScrollBar {
            policy: root.showScrollBar ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 5
                radius: width / 2
                color: root.scrollBarColor
                opacity: parent.active ? 0.8 : 0.3
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            background: Rectangle { color: "transparent" }
        }

        // Expose view reference via attached property name for delegates
        property alias view: lv
    }

    // Expose count and currentIndex for external access
    property alias count:        lv.count
    property alias currentIndex: lv.currentIndex

    function positionViewAtIndex(index, mode) { lv.positionViewAtIndex(index, mode) }
    function positionViewAtBeginning() { lv.positionViewAtBeginning() }
    function positionViewAtEnd() { lv.positionViewAtEnd() }
}
