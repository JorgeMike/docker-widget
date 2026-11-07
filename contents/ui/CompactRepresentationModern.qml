import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// En el panel: ícono de Docker con una pastilla que cuenta los que corren.
MouseArea {
    id: compact

    hoverEnabled: true
    onClicked: root.expanded = !root.expanded

    Kirigami.Icon {
        anchors.fill: parent
        anchors.margins: 1
        source: Qt.resolvedUrl("../images/whale.svg")
        isMask: true
        color: compact.containsMouse ? root.dockerBlue : Kirigami.Theme.textColor
        active: compact.containsMouse
        scale: compact.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
    }

    Rectangle {
        visible: root.loaded
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -2
        anchors.bottomMargin: -1
        height: Math.max(13, Math.round(parent.height * 0.48))
        width: Math.max(height, badgeLabel.implicitWidth + 8)
        radius: height / 2
        border.width: 1.5
        border.color: Kirigami.Theme.backgroundColor
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.errorText !== "" ? "#f87171" : root.runningCount > 0 ? "#34d399" : "#9ca3af"
            }
            GradientStop {
                position: 1
                color: root.errorText !== "" ? "#dc2626" : root.runningCount > 0 ? "#059669" : "#6b7280"
            }
        }

        PlasmaComponents3.Label {
            id: badgeLabel
            anchors.centerIn: parent
            text: root.errorText !== "" ? "!" : root.runningCount
            color: "white"
            font.bold: true
            font.pixelSize: Math.round(parent.height * 0.68)
        }
    }
}
