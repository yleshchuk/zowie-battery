import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes

KCM.SimpleKCM {
    id: page

    property string cfg_language
    property string cfg_indicatorStyle
    property string cfg_iconName
    property bool cfg_showPercent

    readonly property var languages: ["system", "en", "uk"]
    readonly property var styles: ["ring", "vertical", "horizontal", "text"]
    readonly property var presetIcons: ["zowie-ec-symbolic", "zowie-mouse-symbolic", "zowie-mouse-wireless-symbolic", "input-mouse"]

    Translations {
        id: trans
        currentLanguage: page.cfg_language
    }

    Kirigami.FormLayout {
        QQC2.ComboBox {
            Kirigami.FormData.label: trans.tr("Language:")
            model: [trans.tr("System"), "English", "Українська"]
            currentIndex: page.languages.indexOf(page.cfg_language)
            onActivated: page.cfg_language = page.languages[currentIndex]
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: trans.tr("Indicator:")
            model: [trans.tr("Ring"), trans.tr("Vertical bar"), trans.tr("Horizontal bar"), trans.tr("Text")]
            currentIndex: page.styles.indexOf(page.cfg_indicatorStyle)
            onActivated: page.cfg_indicatorStyle = page.styles[currentIndex]
        }

        QQC2.CheckBox {
            text: trans.tr("Show percentage")
            enabled: page.cfg_indicatorStyle !== "text"
            checked: page.cfg_showPercent
            onToggled: page.cfg_showPercent = checked
        }

        RowLayout {
            Kirigami.FormData.label: trans.tr("Icon:")

            Repeater {
                model: page.presetIcons

                QQC2.ToolButton {
                    required property string modelData
                    contentItem: Kirigami.Icon {
                        implicitWidth: Kirigami.Units.iconSizes.medium
                        implicitHeight: Kirigami.Units.iconSizes.medium
                        source: modelData.startsWith("zowie-") ? Qt.resolvedUrl("../icons/" + modelData + ".svg") : modelData
                        isMask: modelData.startsWith("zowie-")
                        color: Kirigami.Theme.textColor
                    }
                    checkable: true
                    checked: page.cfg_iconName === modelData
                    onClicked: page.cfg_iconName = modelData
                    QQC2.ToolTip.text: modelData
                    QQC2.ToolTip.visible: hovered
                }
            }

            QQC2.Button {
                icon.name: page.presetIcons.includes(page.cfg_iconName) ? "document-open" : page.cfg_iconName
                text: trans.tr("Choose…")
                onClicked: iconDialog.open()
            }
        }

        KIconThemes.IconDialog {
            id: iconDialog
            onIconNameChanged: if (iconName) page.cfg_iconName = iconName
        }
    }
}
