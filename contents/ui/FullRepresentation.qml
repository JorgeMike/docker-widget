import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: full

    readonly property int gu: Kirigami.Units.gridUnit
    readonly property real cardRadius: gu * 1.1
    readonly property real shadowMargin: root.inPanel ? 0 : Kirigami.Units.largeSpacing
    readonly property color fgDim: Qt.rgba(1, 1, 1, 0.6)

    Layout.minimumWidth: gu * 22
    Layout.minimumHeight: gu * 18
    Layout.preferredWidth: gu * 26
    Layout.preferredHeight: gu * 24

    // ---- Tarjeta ----
    Kirigami.ShadowedRectangle {
        id: cardShadow
        anchors.fill: parent
        anchors.margins: full.shadowMargin
        radius: full.cardRadius
        color: "#111418"
        shadow.size: full.shadowMargin > 0 ? 28 : 0
        shadow.yOffset: 6
        shadow.color: Qt.rgba(0, 0, 0, 0.45)
    }

    Item {
        id: card
        anchors.fill: cardShadow
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: cardMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        Rectangle { anchors.fill: parent; color: "#111418" }
        // Resplandor azul Docker arriba
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.45
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0.14, 0.59, 0.93, 0.22) }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: full.gu
            spacing: full.gu * 0.75

            // ---- Encabezado ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Kirigami.ShadowedRectangle {
                    implicitWidth: full.gu * 2.4
                    implicitHeight: implicitWidth
                    radius: full.gu * 0.65
                    color: "#1d63ed"
                    shadow.size: 14
                    shadow.yOffset: 3
                    shadow.color: Qt.rgba(0.14, 0.59, 0.93, 0.45)
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#3ba9f5" }
                            GradientStop { position: 1; color: "#1d63ed" }
                        }
                    }
                    Image {
                        anchors.centerIn: parent
                        width: Math.round(parent.width * 0.72)
                        height: width
                        source: Qt.resolvedUrl("../images/whale.svg")
                        sourceSize: Qt.size(width, height)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    PlasmaComponents3.Label {
                        text: "Docker"
                        color: "white"
                        font.pixelSize: Math.round(full.gu * 1.25)
                        font.weight: Font.Bold
                    }
                    PlasmaComponents3.Label {
                        text: !root.loaded ? "Cargando…"
                            : root.errorText !== "" && root.containers.length === 0 ? "Sin conexión"
                            : root.runningCount + " de " + root.containers.length + " corriendo"
                        color: full.fgDim
                        font: Kirigami.Theme.smallFont
                    }
                }

                Item { Layout.fillWidth: true }

                IconButton {
                    iconName: "view-refresh"
                    tip: "Actualizar"
                    tint: root.dockerBlue
                    spinning: root.manualRefresh
                    onClicked: {
                        root.manualRefresh = true
                        root.refresh()
                    }
                }
            }

            // ---- Filtros ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                // Control segmentado Todos / Activos
                Rectangle {
                    id: segmented
                    implicitWidth: segRow.implicitWidth + 6
                    implicitHeight: search.implicitHeight
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.06)

                    Rectangle {
                        y: 3
                        height: parent.height - 6
                        radius: height / 2
                        width: (root.onlyRunning ? segActive : segAll).width
                        x: 3 + (root.onlyRunning ? segActive.x : segAll.x)
                        color: Qt.rgba(1, 1, 1, 0.14)
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    Row {
                        id: segRow
                        anchors.verticalCenter: parent.verticalCenter
                        x: 3
                        Repeater {
                            model: [
                                { label: "Todos", count: root.containers.length, active: false },
                                { label: "Activos", count: root.runningCount, active: true }
                            ]
                            delegate: Item {
                                required property var modelData
                                required property int index
                                Component.onCompleted: if (index === 0) segAll.target = this; else segActive.target = this
                                width: segLabel.implicitWidth + full.gu * 1.2
                                height: segmented.height - 6
                                PlasmaComponents3.Label {
                                    id: segLabel
                                    anchors.centerIn: parent
                                    text: modelData.label + "  " + modelData.count
                                    color: root.onlyRunning === modelData.active ? "white" : full.fgDim
                                    font.weight: Font.DemiBold
                                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.onlyRunning = modelData.active
                                }
                            }
                        }
                    }
                    // Referencias a los dos segmentos para mover el indicador
                    QtObject { id: segAll; property Item target; readonly property real x: target ? target.x : 0; readonly property real width: target ? target.width : 0 }
                    QtObject { id: segActive; property Item target; readonly property real x: target ? target.x : 0; readonly property real width: target ? target.width : 0 }
                }

                // Búsqueda
                PlasmaComponents3.TextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: "Buscar…"
                    color: "white"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                    leftPadding: full.gu * 1.9
                    onTextChanged: root.filterText = text.toLowerCase()
                    background: Rectangle {
                        radius: height / 2
                        color: search.activeFocus ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: search.activeFocus ? Qt.rgba(0.14, 0.59, 0.93, 0.7) : Qt.rgba(1, 1, 1, 0.06)
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Kirigami.Icon {
                            anchors.left: parent.left
                            anchors.leftMargin: full.gu * 0.6
                            anchors.verticalCenter: parent.verticalCenter
                            width: Kirigami.Units.iconSizes.small
                            height: width
                            source: "search"
                            isMask: true
                            color: Qt.rgba(1, 1, 1, 0.5)
                        }
                    }
                }
            }

            // ---- Error (cuando ya hay lista) ----
            Rectangle {
                Layout.fillWidth: true
                visible: root.errorText !== "" && root.containers.length > 0
                implicitHeight: errLabel.implicitHeight + Kirigami.Units.largeSpacing * 1.5
                radius: full.gu * 0.6
                color: Qt.rgba(0.97, 0.44, 0.44, 0.14)
                border.width: 1
                border.color: Qt.rgba(0.97, 0.44, 0.44, 0.35)
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.largeSpacing * 0.75
                    Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.small
                        implicitHeight: implicitWidth
                        source: "dialog-error-symbolic"
                        isMask: true
                        color: "#fca5a5"
                    }
                    PlasmaComponents3.Label {
                        id: errLabel
                        Layout.fillWidth: true
                        text: root.errorText
                        color: "#fecaca"
                        font: Kirigami.Theme.smallFont
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }

            // ---- Lista ----
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Kirigami.Units.smallSpacing
                model: viewModel
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: PlasmaComponents3.ScrollBar {}

                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }

                section.property: "group"
                section.delegate: Item {
                    required property string section
                    readonly property var members: root.containers.filter(c => c.group === section)
                    width: ListView.view.width
                    height: full.gu * 1.9
                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        anchors.leftMargin: 4
                        spacing: Kirigami.Units.smallSpacing
                        Kirigami.Icon {
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: implicitWidth
                            source: section !== root.noProject ? "folder-symbolic" : "package-symbolic"
                            isMask: true
                            color: full.fgDim
                        }
                        PlasmaComponents3.Label {
                            text: section.toUpperCase()
                            color: full.fgDim
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            font.weight: Font.Bold
                            font.letterSpacing: 1
                        }
                        Rectangle {
                            implicitWidth: countLabel.implicitWidth + 10
                            implicitHeight: countLabel.implicitHeight + 2
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.08)
                            PlasmaComponents3.Label {
                                id: countLabel
                                anchors.centerIn: parent
                                text: members.filter(c => c.state === "running").length + "/" + members.length
                                color: full.fgDim
                                font.pointSize: Kirigami.Theme.smallFont.pointSize * 0.9
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }

                delegate: ContainerRow {
                    width: ListView.view.width - (list.QQC2.ScrollBar.vertical.visible ? Kirigami.Units.largeSpacing : 0)
                }
            }
        }

        // ---- Estado vacío / error ----
        ColumnLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: full.gu * 2
            width: parent.width - full.gu * 4
            visible: list.count === 0 && root.loaded
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: full.gu * 3
                implicitHeight: implicitWidth
                source: root.errorText !== "" ? "dialog-error-symbolic" : Qt.resolvedUrl("../images/whale.svg")
                isMask: true
                color: root.errorText !== "" ? "#f87171" : full.fgDim
            }
            PlasmaComponents3.Label {
                Layout.alignment: Qt.AlignHCenter
                text: root.errorText !== "" ? "No se pudo hablar con Docker"
                    : root.containers.length === 0 ? "No hay contenedores"
                    : "Ningún contenedor coincide"
                color: "white"
                font.weight: Font.DemiBold
            }
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.errorText
                visible: text !== ""
                color: full.fgDim
                font: Kirigami.Theme.smallFont
                wrapMode: Text.Wrap
            }
        }
    }

    Item {
        id: cardMask
        anchors.fill: card
        layer.enabled: true
        layer.smooth: true
        visible: false
        Rectangle { anchors.fill: parent; radius: full.cardRadius }
    }

    Rectangle {
        anchors.fill: card
        radius: full.cardRadius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.09)
    }
}
