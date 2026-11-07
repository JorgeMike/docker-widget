import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

// Estilo Plasma: componentes estándar y colores del tema (claro u oscuro).
PlasmaExtras.Representation {
    Layout.minimumWidth: Kirigami.Units.gridUnit * 22
    Layout.minimumHeight: Kirigami.Units.gridUnit * 18
    Layout.preferredWidth: Kirigami.Units.gridUnit * 26
    Layout.preferredHeight: Kirigami.Units.gridUnit * 24
    collapseMarginsHint: true

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            PlasmaExtras.SearchField {
                Layout.fillWidth: true
                placeholderText: "Filtrar contenedores…"
                onTextChanged: root.filterText = text.toLowerCase()
            }
            PlasmaComponents3.ToolButton {
                icon.name: "view-filter"
                checkable: true
                checked: root.onlyRunning
                onToggled: root.onlyRunning = checked
                PlasmaComponents3.ToolTip { text: "Solo los que están corriendo" }
            }
            PlasmaComponents3.ToolButton {
                icon.name: "view-refresh"
                onClicked: root.refresh()
                PlasmaComponents3.ToolTip { text: "Actualizar" }
            }
        }
    }

    footer: PlasmaExtras.PlasmoidHeading {
        position: PlasmaComponents3.ToolBar.Footer
        visible: root.errorText !== "" && root.containers.length > 0
        PlasmaComponents3.Label {
            anchors.fill: parent
            text: root.errorText
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }
    }

    PlasmaComponents3.ScrollView {
        anchors.fill: parent

        ListView {
            id: list
            clip: true
            spacing: Kirigami.Units.smallSpacing
            topMargin: Kirigami.Units.smallSpacing
            bottomMargin: Kirigami.Units.smallSpacing
            model: viewModel

            section.property: "group"
            section.delegate: Kirigami.ListSectionHeader {
                required property string section
                width: ListView.view.width
                text: section
            }

            delegate: PlasmaComponents3.ItemDelegate {
                id: row
                required property var model
                readonly property var c: model
                readonly property bool isRunning: c.state === "running"
                readonly property string pending: root.busy[c.id] || ""
                readonly property var ports: c.hostPorts ? c.hostPorts.split(",") : []

                width: ListView.view.width
                hoverEnabled: true
                down: false

                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: Kirigami.Units.gridUnit * 0.6
                        height: width
                        radius: width / 2
                        color: root.stateColor(row.c.state)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: row.c.name
                            font.bold: true
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            text: row.c.image + " · " + row.c.status
                            font: Kirigami.Theme.smallFont
                            opacity: 0.75
                            elide: Text.ElideRight
                            textFormat: Text.PlainText
                        }
                        // Puertos como enlaces: clic para abrir en el navegador
                        PlasmaComponents3.Label {
                            Layout.fillWidth: true
                            visible: row.isRunning && row.ports.length > 0
                            text: row.ports.map(p => '<a href="http://localhost:' + p + '">:' + p + '</a>').join("  ")
                            textFormat: Text.StyledText
                            font: Kirigami.Theme.smallFont
                            elide: Text.ElideRight
                            onLinkActivated: link => Qt.openUrlExternally(link)
                            HoverHandler { cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor }
                        }
                    }

                    PlasmaComponents3.BusyIndicator {
                        visible: row.pending !== ""
                        running: visible
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                    }

                    PlasmaComponents3.ToolButton {
                        visible: row.pending === "" && !row.isRunning
                        icon.name: "media-playback-start"
                        onClicked: root.act("start", row.c)
                        PlasmaComponents3.ToolTip { text: "Levantar" }
                    }
                    PlasmaComponents3.ToolButton {
                        visible: row.pending === "" && row.isRunning
                        icon.name: "view-refresh"
                        onClicked: root.act("restart", row.c)
                        PlasmaComponents3.ToolTip { text: "Reiniciar" }
                    }
                    PlasmaComponents3.ToolButton {
                        visible: row.pending === "" && row.isRunning
                        icon.name: "media-playback-stop"
                        onClicked: root.act("stop", row.c)
                        PlasmaComponents3.ToolTip { text: "Detener" }
                    }
                }
            }

            PlasmaExtras.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 4
                visible: list.count === 0 && root.loaded
                iconName: root.errorText !== "" ? "dialog-error" : "run-build"
                text: root.errorText !== "" ? "No se pudo hablar con Docker"
                      : root.containers.length === 0 ? "No hay contenedores"
                      : "Ningún contenedor coincide"
                explanation: root.errorText
            }
        }
    }
}
