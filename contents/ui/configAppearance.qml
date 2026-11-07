import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property string cfg_style
    property string cfg_styleDefault

    Kirigami.FormLayout {
        QQC2.RadioButton {
            Kirigami.FormData.label: "Estilo:"
            text: "Plasma — sigue tu tema, colores y modo claro/oscuro"
            checked: cfg_style === "plasma"
            onToggled: if (checked) cfg_style = "plasma"
        }
        QQC2.RadioButton {
            text: "Moderno — tarjeta oscura con efectos"
            checked: cfg_style !== "plasma"
            onToggled: if (checked) cfg_style = "modern"
        }
        QQC2.Label {
            text: "Solo se carga el diseño elegido."
            opacity: 0.6
            font: Kirigami.Theme.smallFont
        }
    }
}
