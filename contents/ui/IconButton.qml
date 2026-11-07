import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

// Botón redondo con ícono teñido; se ilumina con su color al pasar el mouse.
Item {
    id: btn

    property string iconName
    property string tip
    property color tint: "white"
    property real size: Kirigami.Units.gridUnit * 1.7
    property bool spinning: false

    signal clicked()

    implicitWidth: size
    implicitHeight: size
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(btn.tint.r, btn.tint.g, btn.tint.b,
                       mouse.pressed ? 0.28 : mouse.containsMouse ? 0.18 : 0)
        border.width: 1
        border.color: Qt.rgba(btn.tint.r, btn.tint.g, btn.tint.b, mouse.containsMouse ? 0.35 : 0)
        scale: mouse.pressed ? 0.9 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    Kirigami.Icon {
        id: icon
        anchors.centerIn: parent
        width: Math.round(btn.size * 0.55)
        height: width
        source: btn.iconName
        isMask: true
        color: mouse.containsMouse ? btn.tint : Qt.rgba(1, 1, 1, 0.8)

        RotationAnimation on rotation {
            running: btn.spinning
            from: 0; to: 360
            duration: 800
            loops: Animation.Infinite
            onStopped: icon.rotation = 0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: btn.clicked()
    }

    PlasmaComponents3.ToolTip {
        text: btn.tip
        visible: mouse.containsMouse && btn.tip !== ""
        delay: Kirigami.Units.toolTipDelay
    }
}
