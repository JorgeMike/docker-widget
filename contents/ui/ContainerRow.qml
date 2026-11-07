import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// Una fila por contenedor: estado, nombre, imagen, puertos y acciones.
Rectangle {
    id: row

    required property var model
    readonly property var c: model
    readonly property bool isRunning: c.state === "running"
    readonly property string pending: root.busy[c.id] || ""
    readonly property color stateColor: root.stateColor(c.state)
    readonly property var ports: c.hostPorts ? c.hostPorts.split(",") : []

    implicitHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.gridUnit * 0.7
    color: hover.hovered ? Qt.rgba(1, 1, 1, 0.085) : Qt.rgba(1, 1, 1, 0.045)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, hover.hovered ? 0.1 : 0.05)
    Behavior on color { ColorAnimation { duration: 120 } }

    HoverHandler { id: hover }

    // Línea de color a la izquierda según el estado
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 1
        width: 3
        height: parent.height * 0.5
        radius: 2
        color: row.stateColor
        opacity: row.isRunning ? 0.9 : 0.35
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.largeSpacing * 1.5
        anchors.rightMargin: Kirigami.Units.smallSpacing * 1.5
        spacing: Kirigami.Units.largeSpacing

        StatusDot {
            Layout.alignment: Qt.AlignVCenter
            color: row.stateColor
            pulsing: row.isRunning
            size: Math.round(Kirigami.Units.gridUnit * 0.55)
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: row.c.name
                color: "white"
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                PlasmaComponents3.Label {
                    Layout.maximumWidth: Math.min(implicitWidth, row.width * 0.4)
                    text: row.c.image
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.family: "monospace"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    elide: Text.ElideMiddle
                    textFormat: Text.PlainText
                }
                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: "· " + row.c.status
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font: Kirigami.Theme.smallFont
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }

            // Puertos publicados: clic para abrir en el navegador
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 4
                visible: row.isRunning && row.ports.length > 0

                Repeater {
                    model: row.ports
                    Rectangle {
                        required property string modelData
                        width: portLabel.implicitWidth + 12
                        height: portLabel.implicitHeight + 4
                        radius: height / 2
                        color: Qt.rgba(0.14, 0.59, 0.93, portMouse.containsMouse ? 0.32 : 0.16)
                        border.width: 1
                        border.color: Qt.rgba(0.14, 0.59, 0.93, 0.35)
                        PlasmaComponents3.Label {
                            id: portLabel
                            anchors.centerIn: parent
                            text: ":" + parent.modelData
                            color: "#93c5fd"
                            font.family: "monospace"
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                        MouseArea {
                            id: portMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("http://localhost:" + parent.modelData)
                        }
                        PlasmaComponents3.ToolTip {
                            text: "Abrir localhost:" + parent.modelData
                            visible: portMouse.containsMouse
                        }
                    }
                }
            }
        }

        PlasmaComponents3.BusyIndicator {
            visible: row.pending !== ""
            running: visible
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
        }

        Row {
            visible: row.pending === ""
            spacing: 2
            // Más discretas hasta pasar el mouse
            opacity: hover.hovered ? 1 : 0.55
            Behavior on opacity { NumberAnimation { duration: 150 } }

            IconButton {
                visible: !row.isRunning
                iconName: "media-playback-start"
                tip: "Levantar"
                tint: "#34d399"
                onClicked: root.act("start", row.c)
            }
            IconButton {
                visible: row.isRunning
                iconName: "view-refresh"
                tip: "Reiniciar"
                tint: "#fbbf24"
                onClicked: root.act("restart", row.c)
            }
            IconButton {
                visible: row.isRunning
                iconName: "media-playback-stop"
                tip: "Detener"
                tint: "#f87171"
                onClicked: root.act("stop", row.c)
            }
        }
    }
}
