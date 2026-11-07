import QtQuick

// Punto de estado; si está corriendo, emite un pulso suave.
Item {
    id: dot

    property color color: "white"
    property bool pulsing: false
    property bool glow: false
    property real size: 10

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: halo
        anchors.centerIn: parent
        width: dot.size
        height: width
        radius: width / 2
        color: dot.color
        opacity: 0
        visible: dot.pulsing

        ParallelAnimation {
            running: dot.pulsing
            loops: Animation.Infinite
            NumberAnimation { target: halo; property: "scale"; from: 1; to: 2.6; duration: 1600; easing.type: Easing.OutCubic }
            NumberAnimation { target: halo; property: "opacity"; from: 0.5; to: 0; duration: 1600; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: dot.size
        height: width
        radius: width / 2
        color: dot.color
        border.width: 2
        border.color: Qt.rgba(dot.color.r, dot.color.g, dot.color.b, 0.35)
    }

    // Halo fijo (sin animación) para que "corriendo" se note sin costo
    Rectangle {
        anchors.centerIn: parent
        z: -1
        width: dot.size * 2
        height: width
        radius: width / 2
        color: Qt.rgba(dot.color.r, dot.color.g, dot.color.b, 0.15)
        visible: dot.glow
    }
}
