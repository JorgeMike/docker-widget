import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
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
             (c.name + " " + c.image + " " + c.project + " " + c.hostPorts).toLowerCase().includes(filterText)))
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
    preferredRepresentation: inPanel ? compactRepresentation : fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                                 || Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property color dockerBlue: "#2496ED"

    function stateColor(state) {
        switch (state) {
        case "running":    return "#34d399"
        case "paused":     return "#fbbf24"
        case "restarting": return "#fbbf24"
        case "dead":       return "#f87171"
        default:           return "#6b7280"
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

    // "0.0.0.0:8080->80/tcp, [::]:8080->80/tcp" -> ["8080"]
    function hostPorts(ports) {
        const seen = []
        const re = /:(\d+)->\d+\/tcp/g
        let m
        while ((m = re.exec(ports)) !== null)
            if (seen.indexOf(m[1]) === -1) seen.push(m[1])
        return seen
    }

    readonly property int stoppedCount: containers.length - runningCount
    property bool manualRefresh: false
    property string lastOutput: ""
    readonly property string noProject: "Sin proyecto"

    function parseList(stdout) {
        const out = []
        for (const line of stdout.split("\n")) {
            if (line.trim() === "") continue
            const p = line.split("|")
            out.push({
                id: p[0], name: p[1], image: p[2], state: p[3], status: p[4],
                project: p[5] || "", ports: p.slice(6).join("|"),
                hostPorts: root.hostPorts(p.slice(6).join("|")).join(","),
                group: p[5] || root.noProject
            })
        }
        // Agrupar por proyecto de compose, luego por nombre
        out.sort((a, b) => (a.project === "") - (b.project === "")
                           || a.project.localeCompare(b.project)
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
                root.manualRefresh = false
                if (code === 0) {
                    root.errorText = ""
                    // Si nada cambió no tocamos la lista: cero redibujos
                    if (data["stdout"] === root.lastOutput) return
                    root.lastOutput = data["stdout"]
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
        // Popup abierto: 3 s · en el escritorio: 10 s · panel cerrado (solo el contador): 30 s
        interval: root.expanded ? 3000 : root.inPanel ? 30000 : 10000
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
    compactRepresentation: CompactRepresentation {}

    // ---------- Vista completa (popup / escritorio) ----------
    fullRepresentation: FullRepresentation {}
}
