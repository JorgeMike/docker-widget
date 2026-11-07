import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // Campos separados por "|"; Ports va al final porque puede traer comas.
    readonly property string listCommand:
        "docker ps -a --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.State}}|{{.Status}}|{{.Label \"com.docker.compose.project\"}}|{{.Ports}}'"

    property var containers: []
    property string errorText: ""
    property bool loaded: false
    property bool onlyRunning: false
    property string filterText: ""
    property var busy: ({})          // id -> acción en curso

    ListModel { id: viewModel }

    function syncView() {
        const items = containers.filter(c =>
            (!onlyRunning || c.state === "running") &&
            (filterText === "" ||
             (c.name + " " + c.image + " " + c.project).toLowerCase().includes(filterText)))
        let same = items.length === viewModel.count
        for (let i = 0; same && i < items.length; i++)
            same = viewModel.get(i).id === items[i].id
        if (same) {
            for (let i = 0; i < items.length; i++) viewModel.set(i, items[i])
        } else {
            viewModel.clear()
            for (const it of items) viewModel.append(it)
        }
    }
    onContainersChanged: syncView()
    onOnlyRunningChanged: syncView()
    onFilterTextChanged: syncView()

    readonly property int runningCount: containers.filter(c => c.state === "running").length

    toolTipMainText: "Docker"
    toolTipSubText: errorText !== ""
        ? "Docker no responde"
        : runningCount + " de " + containers.length + " contenedores corriendo"

    Plasmoid.icon: "docker-desktop"

    // En el escritorio siempre se ve la lista; en el panel, el ícono con contador.
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? fullRepresentation : compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    function stateColor(state) {
        switch (state) {
        case "running":    return Kirigami.Theme.positiveTextColor
        case "paused":     return Kirigami.Theme.neutralTextColor
        case "restarting": return Kirigami.Theme.neutralTextColor
        case "dead":       return Kirigami.Theme.negativeTextColor
        default:           return Kirigami.Theme.disabledTextColor
        }
    }

    function refresh() {
        executable.run(listCommand)
    }

    function act(action, c) {
        const b = Object.assign({}, busy)
        b[c.id] = action
        busy = b
        executable.run("docker " + action + " " + c.id)
    }

    function parseList(stdout) {
        const out = []
        for (const line of stdout.split("\n")) {
            if (line.trim() === "") continue
            const p = line.split("|")
            out.push({
                id: p[0], name: p[1], image: p[2], state: p[3], status: p[4],
                project: p[5] || "", ports: p.slice(6).join("|")
            })
        }
        // Agrupar por proyecto de compose, luego por nombre
        out.sort((a, b) => (a.project || "~").localeCompare(b.project || "~")
                           || a.name.localeCompare(b.name))
        return out
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        function run(cmd) {
            // Un mismo comando solo se ejecuta si no está ya conectado
            if (connectedSources.indexOf(cmd) === -1) connectSource(cmd)
        }

        onNewData: (source, data) => {
            disconnectSource(source)
            const code = data["exit code"]
            if (source === root.listCommand) {
                root.loaded = true
                if (code === 0) {
                    root.errorText = ""
                    root.containers = root.parseList(data["stdout"])
                } else {
                    root.errorText = (data["stderr"] || "").trim() || "Error al ejecutar docker"
                }
                return
            }
            // Fin de una acción start/stop/restart
            const id = source.split(" ").pop()
            const b = Object.assign({}, root.busy)
            delete b[id]
            root.busy = b
            if (code !== 0) {
                root.errorText = (data["stderr"] || "").trim()
                errorTimer.restart()
            }
            root.refresh()
        }
    }

    Timer {
        id: poll
        interval: root.expanded ? 3000 : 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: errorTimer
        interval: 6000
        onTriggered: root.errorText = ""
    }

    onExpandedChanged: if (root.expanded) refresh()

    // ---------- Vista compacta (panel) ----------
    compactRepresentation: MouseArea {
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        Kirigami.Icon {
            anchors.fill: parent
            source: "docker-desktop"
            fallback: "application-x-executable"
            active: parent.containsMouse
        }

        Rectangle {
            visible: root.loaded && root.errorText === ""
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Math.max(height, badgeLabel.implicitWidth + 6)
            height: Math.max(12, parent.height * 0.45)
            radius: height / 2
            color: root.runningCount > 0 ? Kirigami.Theme.positiveTextColor
                                         : Kirigami.Theme.disabledTextColor
            PlasmaComponents3.Label {
                id: badgeLabel
                anchors.centerIn: parent
                text: root.runningCount
                color: "white"
                font.bold: true
                font.pixelSize: parent.height * 0.75
            }
        }
    }

    // ---------- Vista completa (popup / escritorio) ----------
    fullRepresentation: PlasmaExtras.Representation {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 22
        Layout.minimumHeight: Kirigami.Units.gridUnit * 18
        Layout.preferredWidth: Kirigami.Units.gridUnit * 26
        Layout.preferredHeight: Kirigami.Units.gridUnit * 26
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

                section.property: "project"
                section.delegate: Kirigami.ListSectionHeader {
                    required property string section
                    width: ListView.view.width
                    text: section !== "" ? section : "Sin proyecto"
                }

                delegate: PlasmaComponents3.ItemDelegate {
                    id: row
                    required property var model
                    readonly property var c: model
                    readonly property bool isRunning: c.state === "running"
                    readonly property string pending: root.busy[c.id] || ""

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
                            }
                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                text: row.c.image + " · " + row.c.status
                                font: Kirigami.Theme.smallFont
                                opacity: 0.75
                                elide: Text.ElideRight
                            }
                            PlasmaComponents3.Label {
                                Layout.fillWidth: true
                                visible: row.isRunning && row.c.ports !== ""
                                text: row.c.ports
                                font: Kirigami.Theme.smallFont
                                opacity: 0.6
                                elide: Text.ElideRight
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
                    iconName: root.errorText !== "" ? "dialog-error" : "docker-desktop"
                    text: root.errorText !== "" ? "No se pudo hablar con Docker"
                          : root.containers.length === 0 ? "No hay contenedores"
                          : "Ningún contenedor coincide"
                    explanation: root.errorText
                }
            }
        }
    }
}
