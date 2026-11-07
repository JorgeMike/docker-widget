import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// Estilo Plasma en el panel: ballena con el color del texto del tema y un
// contador con el color "positivo" del tema.
MouseArea {
    id: compact

    hoverEnabled: true
    onClicked: root.expanded = !root.expanded

    Kirigami.Icon {
        anchors.fill: parent
        source: Qt.resolvedUrl("../images/whale.svg")
        isMask: true
        color: Kirigami.Theme.textColor
        active: compact.containsMouse
    }

    Rectangle {
        visible: root.loaded
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: Math.max(height, badgeLabel.implicitWidth + 6)
        height: Math.max(12, parent.height * 0.45)
        radius: height / 2
        color: root.errorText !== "" ? Kirigami.Theme.negativeTextColor
             : root.runningCount > 0 ? Kirigami.Theme.positiveTextColor
             : Kirigami.Theme.disabledTextColor
        PlasmaComponents3.Label {
            id: badgeLabel
            anchors.centerIn: parent
            text: root.errorText !== "" ? "!" : root.runningCount
            color: Kirigami.Theme.backgroundColor
            font.bold: true
            font.pixelSize: parent.height * 0.75
        }
    }
}
