import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid

// Carga solo el diseño del estilo elegido (p. ej. FullRepresentationPlasma.qml).
// Los demás diseños no se leen ni ocupan memoria. Reenvía los tamaños
// del diseño para que Plasma los respete.
Loader {
    id: loader

    property string base        // "FullRepresentation" o "CompactRepresentation"
    readonly property string style: Plasmoid.configuration.style === "plasma" ? "Plasma" : "Modern"

    source: base + style + ".qml"

    Layout.minimumWidth: item ? item.Layout.minimumWidth : -1
    Layout.minimumHeight: item ? item.Layout.minimumHeight : -1
    Layout.preferredWidth: item ? item.Layout.preferredWidth : -1
    Layout.preferredHeight: item ? item.Layout.preferredHeight : -1
    Layout.maximumWidth: item ? item.Layout.maximumWidth : Infinity
    Layout.maximumHeight: item ? item.Layout.maximumHeight : Infinity
}
