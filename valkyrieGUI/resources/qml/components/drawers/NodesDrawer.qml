import QtQuick 2.15
import QtQuick.Controls 2.15 as Contrl
import QtQuick.Layouts 1.14
import App.Theme 1.0
import App.NodeRegistry 1.0
import ".."

Item {
    id: root

    signal behaviourSelected(string path, variant infos)
    signal dragStarted(string path, variant infos, real lx, real ly)
    signal dragUpdated(real lx, real ly)
    signal dragEnded(real lx, real ly)

    // Navigation state
    property string navState:        "root"   // "root" or "category"
    property string currentCategory: ""
    property var    categoryData:    ({})      // all paths → nodeList
    property var    categoryKeys:    []        // top-level category names
    property var    currentInfos:    []        // nodes in current category
    property var    breadcrumbArr:   ["home"]

    property bool gridMode: true

    readonly property var _icons: ({
        'Debug':   Icons.bug,
        'Plugins': Icons.codeBraces
    })

    Component.onCompleted: _loadData()

    function _loadData() {
        var data = NodeRegistry.discoverAll()
        root.categoryData = data
        root.categoryKeys = Object.keys(data)
    }

    function _navigateToCategory(catName) {
        root.currentCategory = catName
        root.currentInfos    = root.categoryData[catName] || []
        root.navState        = "category"
        root.breadcrumbArr   = ["home", catName]
    }

    function _navigateToRoot() {
        root.navState        = "root"
        root.currentCategory = ""
        root.currentInfos    = []
        root.breadcrumbArr   = ["home"]
    }

    function _goBack() {
        if (root.navState === "category")
            _navigateToRoot()
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Header ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 38
            color: Qt.darker(ThemeManager.backgroundColor, 1.15)

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.15
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 6

                // Back button
                Item {
                    width: 24; height: 24
                    opacity: root.navState === "category" ? 1.0 : 0.25
                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    ColorIcon {
                        source: "qrc:/icons/arrow-left.svg"
                        color: ThemeManager.textColor
                        width: 14; height: 14; anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.navState === "category"
                        onClicked: root._goBack()
                    }
                }

                ColorIcon {
                    source: "qrc:/icons/magnify.svg"
                    color: ThemeManager.textColor; opacity: 0.4
                    width: 14; height: 14
                }

                // Search field
                Rectangle {
                    Layout.fillWidth: true; height: 26; radius: 4
                    color: Qt.rgba(ThemeManager.textColor.r,
                                   ThemeManager.textColor.g,
                                   ThemeManager.textColor.b, 0.06)
                    border.width: searchInput.activeFocus ? 1 : 0
                    border.color: ThemeManager.primaryColor

                    Text {
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.right: parent.right; anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.navState === "root" ? "Search categories…" : "Search nodes…"
                        font.pixelSize: 12; color: ThemeManager.textColor; opacity: 0.3
                        visible: !searchInput.text.length && !searchInput.activeFocus
                    }
                    TextInput {
                        id: searchInput
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.right: parent.right; anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        height: 22
                        color: ThemeManager.textColor; font.pixelSize: 12; clip: true
                        selectionColor: ThemeManager.primaryColor
                        verticalAlignment: TextInput.AlignVCenter
                    }
                    Rectangle {
                        id: clearBtn
                        visible: searchInput.text.length > 0
                        width: 15; height: 15; radius: 8
                        anchors.right: parent.right; anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(ThemeManager.textColor.r,
                                       ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.2)
                        ColorIcon {
                            source: "qrc:/icons/close.svg"; color: ThemeManager.textColor
                            width: 9; height: 9; anchors.centerIn: parent
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: searchInput.text = ""
                        }
                    }
                }
            }
        }

        // ── Breadcrumb ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 28; clip: true; color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.1
            }

            Row {
                anchors.left: parent.left; anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0; height: 20

                Repeater {
                    model: root.breadcrumbArr

                    delegate: Row {
                        height: 20; spacing: 0

                        Item {
                            width: Math.max(homeIco.implicitWidth,
                                            crumbLbl.implicitWidth) + 10
                            height: 20

                            ColorIcon {
                                id: homeIco
                                visible: index === 0
                                source: "qrc:/icons/home.svg"
                                width: 12; height: 12; anchors.centerIn: parent
                                color: index === root.breadcrumbArr.length - 1
                                       ? ThemeManager.textColor : ThemeManager.primaryColor
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            Text {
                                id: crumbLbl
                                visible: index > 0
                                text: modelData; font.pixelSize: 10
                                anchors.centerIn: parent
                                color: index === root.breadcrumbArr.length - 1
                                       ? ThemeManager.textColor : ThemeManager.primaryColor
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: index < root.breadcrumbArr.length - 1
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (index === 0) root._navigateToRoot()
                                }
                            }
                        }

                        Text {
                            visible: index < root.breadcrumbArr.length - 1
                            text: " › "; font.pixelSize: 10
                            color: ThemeManager.textColor; opacity: 0.35
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // ── Toolbar (only in category view) ─────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 26; color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.08
            }

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 4; spacing: 0

                Text {
                    text: {
                        if (root.navState === "root") {
                            var q = searchInput.text.toLowerCase()
                            var cnt = q
                                ? root.categoryKeys.filter(function(k){
                                      return k.toLowerCase().indexOf(q) >= 0
                                  }).length
                                : root.categoryKeys.length
                            return cnt + " categories"
                        }
                        var q2 = searchInput.text.toLowerCase()
                        if (!q2) return root.currentInfos.length + " nodes"
                        var cnt2 = root.currentInfos.filter(function(n){
                            return n.name.toLowerCase().indexOf(q2) >= 0
                        }).length
                        return cnt2 + " / " + root.currentInfos.length
                    }
                    font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.4
                }

                Item { Layout.fillWidth: true }

                // View toggle — only relevant in category view
                Item {
                    width: 24; height: 24
                    visible: root.navState === "category"
                    ColorIcon {
                        source: root.gridMode ? "qrc:/icons/view-list.svg" : "qrc:/icons/view-grid.svg"
                        color: ThemeManager.textColor; opacity: 0.55
                        width: 14; height: 14; anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.gridMode = !root.gridMode
                    }
                }
            }
        }

        // ── Content area ────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true

            // ── ROOT: category list ────────────────────────────────────────
            ListView {
                id: catList
                anchors.fill: parent; clip: true
                visible: root.navState === "root"

                Contrl.ScrollBar.vertical: Contrl.ScrollBar {
                    contentItem: Rectangle {
                        implicitWidth: 3; radius: 1.5
                        color: ThemeManager.primaryColor; opacity: 0.4
                    }
                }

                property var displayKeys: {
                    var q = searchInput.text.toLowerCase()
                    if (!q) return root.categoryKeys
                    return root.categoryKeys.filter(function(k){
                        return k.toLowerCase().indexOf(q) >= 0
                    })
                }

                model: displayKeys

                // Empty state
                Column {
                    anchors.centerIn: parent; spacing: 10
                    visible: catList.count === 0

                    ColorIcon {
                        source: "qrc:/icons/chart-line.svg"
                        color: ThemeManager.textColor; opacity: 0.18
                        width: 28; height: 28; anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "No categories"
                        font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.3
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                delegate: Rectangle {
                    width: catList.width; height: 44
                    color: catRowMouse.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r,
                                     ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.08)
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 10; anchors.rightMargin: 10
                        height: 1; color: ThemeManager.primaryColor; opacity: 0.07
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14; anchors.rightMargin: 10; spacing: 10

                        // Category icon
                        Rectangle {
                            width: 28; height: 28; radius: 6
                            color: Qt.rgba(ThemeManager.primaryColor.r,
                                           ThemeManager.primaryColor.g,
                                           ThemeManager.primaryColor.b, 0.12)
                            ColorIcon {
                                anchors.centerIn: parent
                                source: root._icons[modelData] || "qrc:/icons/folder.svg"
                                color: ThemeManager.primaryColor
                                width: 14; height: 14
                            }
                        }

                        Column {
                            Layout.fillWidth: true; spacing: 2
                            Text {
                                text: modelData; font.pixelSize: 12; font.bold: true
                                color: ThemeManager.textColor; elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: (root.categoryData[modelData] || []).length + " nodes"
                                font.pixelSize: 10
                                color: ThemeManager.textColor; opacity: 0.45
                            }
                        }

                        ColorIcon {
                            source: "qrc:/icons/chevron-right.svg"
                            color: ThemeManager.textColor; opacity: 0.3
                            width: 12; height: 12
                        }
                    }

                    MouseArea {
                        id: catRowMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._navigateToCategory(modelData)
                    }
                }
            }

            // ── CATEGORY: node cards ───────────────────────────────────────
            Item {
                anchors.fill: parent
                visible: root.navState === "category"

                property var filtered: {
                    var q = searchInput.text.toLowerCase()
                    if (!q) return root.currentInfos
                    return root.currentInfos.filter(function(n){
                        return n.name.toLowerCase().indexOf(q) >= 0
                    })
                }

                // Empty state
                Column {
                    anchors.centerIn: parent; spacing: 10
                    visible: parent.filtered.length === 0

                    ColorIcon {
                        source: Icons.chartLine
                        color: ThemeManager.textColor; opacity: 0.18
                        width: 28; height: 28; anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: root.currentInfos.length === 0 ? "Empty category" : "No results"
                        font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.3
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                GridView {
                    id: cardGrid
                    anchors.fill: parent; anchors.margins: 4; clip: true

                    property int cols: root.gridMode
                                       ? Math.max(1, Math.floor(width / 130)) : 1
                    cellWidth:  root.gridMode ? Math.floor(width / cols) : width
                    cellHeight: root.gridMode ? 92 : 50

                    model: parent.filtered

                    Contrl.ScrollBar.vertical: Contrl.ScrollBar {
                        contentItem: Rectangle {
                            implicitWidth: 3; radius: 1.5
                            color: ThemeManager.primaryColor; opacity: 0.4
                        }
                    }

                    delegate: Item {
                        id: cardDelegate
                        width: cardGrid.cellWidth
                        height: cardGrid.cellHeight

                        property bool _dragging: false
                        property real _startX:   0
                        property real _startY:   0

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 3; radius: 5
                            color: cardMouse.containsMouse && !cardDelegate._dragging
                                   ? Qt.lighter(ThemeManager.surfaceColor, 1.12)
                                   : ThemeManager.surfaceColor
                            border.width: 1
                            border.color: cardMouse.containsMouse
                                          ? ThemeManager.primaryColor
                                          : Qt.rgba(ThemeManager.primaryColor.r,
                                                    ThemeManager.primaryColor.g,
                                                    ThemeManager.primaryColor.b, 0.25)
                            Behavior on color        { ColorAnimation { duration: 80 } }
                            Behavior on border.color { ColorAnimation { duration: 80 } }

                            // Grid mode content
                            ColumnLayout {
                                visible: root.gridMode
                                anchors.fill: parent; anchors.margins: 8; spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name; font.pixelSize: 11; font.bold: true
                                    color: ThemeManager.textColor; elide: Text.ElideRight
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.desc || ""
                                    font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.5
                                    elide: Text.ElideRight; wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                }
                                Item { Layout.fillHeight: true }
                                Row {
                                    spacing: 6
                                    Text {
                                        text: "↑" + modelData.outputs_count
                                        font.pixelSize: 9
                                        color: ThemeManager.primaryColor; opacity: 0.8
                                    }
                                    Text {
                                        text: "↓" + modelData.inputs_count
                                        font.pixelSize: 9
                                        color: ThemeManager.textColor; opacity: 0.5
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: "drag →"
                                        font.pixelSize: 8
                                        color: ThemeManager.textColor; opacity: 0.22
                                    }
                                }
                            }

                            // List mode content
                            RowLayout {
                                visible: !root.gridMode
                                anchors.fill: parent; anchors.margins: 6
                                anchors.leftMargin: 10; spacing: 8

                                ColorIcon {
                                    source: Icons.chartLine
                                    color: ThemeManager.primaryColor; width: 14; height: 14
                                }
                                Column {
                                    Layout.fillWidth: true; spacing: 1
                                    Text {
                                        text: modelData.name; font.pixelSize: 12
                                        color: ThemeManager.textColor; elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: "↑" + modelData.outputs_count + "  ↓" + modelData.inputs_count
                                        font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.45
                                    }
                                }
                                Text {
                                    text: "drag →"; font.pixelSize: 9
                                    color: ThemeManager.primaryColor; opacity: 0.35
                                }
                            }

                            // Drag tint
                            Rectangle {
                                anchors.fill: parent; radius: parent.radius
                                color: ThemeManager.primaryColor; opacity: 0.18
                                visible: cardDelegate._dragging
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent; hoverEnabled: true
                            acceptedButtons: Qt.LeftButton
                            preventStealing: true
                            cursorShape: cardDelegate._dragging
                                         ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            onPressed: {
                                cardDelegate._startX = mouseX
                                cardDelegate._startY = mouseY
                            }
                            onPositionChanged: {
                                if (!cardDelegate._dragging && pressed) {
                                    var dx = mouseX - cardDelegate._startX
                                    var dy = mouseY - cardDelegate._startY
                                    if ((dx * dx + dy * dy) > 64) {
                                        cardDelegate._dragging = true
                                        var lp = mapToItem(root, mouseX, mouseY)
                                        root.dragStarted(root.currentCategory, modelData, lp.x, lp.y)
                                    }
                                }
                                if (cardDelegate._dragging) {
                                    var lp2 = mapToItem(root, mouseX, mouseY)
                                    root.dragUpdated(lp2.x, lp2.y)
                                }
                            }
                            onReleased: {
                                if (cardDelegate._dragging) {
                                    cardDelegate._dragging = false
                                    var lp = mapToItem(root, mouseX, mouseY)
                                    root.dragEnded(lp.x, lp.y)
                                }
                            }
                            onCanceled: {
                                if (cardDelegate._dragging) {
                                    cardDelegate._dragging = false
                                    root.dragEnded(-9999, -9999)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

