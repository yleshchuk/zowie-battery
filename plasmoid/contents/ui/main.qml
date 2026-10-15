import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property var status: ({})
    readonly property bool linked: status.linked === true
    readonly property int percent: linked ? (status.battery_estimate ?? status.battery_percent) : 0
    readonly property string percentText: linked ? percent + "%" : "—"
    readonly property string rateText: status.polling_hz ? status.polling_hz + " " + tr("Hz") : tr("— (move the mouse)")
    readonly property string modeText: !status.mode ? tr("not connected")
        : !linked ? tr("mouse is not linked")
        : status.mode === "wired" ? tr("cable") : tr("receiver")
    readonly property color levelColor: !linked ? Kirigami.Theme.disabledTextColor
        : percent <= 20 ? Kirigami.Theme.negativeTextColor
        : percent <= 40 ? Kirigami.Theme.neutralTextColor
        : Kirigami.Theme.positiveTextColor
    readonly property color barColor: linked && percent <= 20 ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor

    function tr(text) {
        return trans.tr(text)
    }

    Translations {
        id: trans
        currentLanguage: Plasmoid.configuration.language
    }

    Plasmoid.icon: Plasmoid.configuration.iconName
    toolTipMainText: "Zowie EC-CW"
    toolTipSubText: tr("Battery") + ": " + percentText + "\n" + tr("Polling rate") + ": " + rateText + "\n" + tr("Connection") + ": " + modeText

    Plasma5Support.DataSource {
        id: reader
        readonly property string command: 'cat "$XDG_RUNTIME_DIR/zowie/status.json"'
        engine: "executable"
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            try {
                root.status = JSON.parse(data.stdout)
            } catch (e) {
                root.status = {}
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.connectSource(reader.command)
    }

    compactRepresentation: MouseArea {
        id: compact

        readonly property string indicator: Plasmoid.configuration.indicatorStyle
        readonly property real size: Math.round(height * 0.8)

        Layout.minimumWidth: row.implicitWidth
        Layout.preferredWidth: row.implicitWidth
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing
            opacity: root.linked ? 1 : 0.5

            BatteryRing {
                Layout.preferredWidth: compact.size
                Layout.preferredHeight: compact.size
                percent: compact.indicator === "ring" ? root.percent : 0
                lineWidth: compact.indicator === "ring" ? Math.max(2, compact.size / 10) : 0
                ringColor: root.levelColor

                Kirigami.Icon {
                    width: compact.indicator === "ring" ? compact.size * 0.6 : compact.size
                    height: width
                    source: Plasmoid.configuration.iconName
                }
            }

            Item {
                visible: compact.indicator === "vertical"
                Layout.preferredWidth: Math.max(4, Math.round(compact.size / 5))
                Layout.preferredHeight: Math.round(compact.size * 0.85)

                Rectangle {
                    anchors.fill: parent
                    radius: 1
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.25)
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.round(parent.height * root.percent / 100)
                    radius: 1
                    color: root.barColor
                }
            }

            Item {
                visible: compact.indicator === "horizontal"
                Layout.preferredWidth: Math.round(compact.size * 1.1)
                Layout.preferredHeight: Math.round(compact.size * 0.5)

                Rectangle {
                    id: body
                    width: parent.width - nub.width
                    height: parent.height
                    radius: 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.alpha(Kirigami.Theme.textColor, 0.6)

                    Rectangle {
                        x: 2
                        y: 2
                        width: Math.round((body.width - 4) * root.percent / 100)
                        height: body.height - 4
                        radius: 1
                        color: root.barColor
                    }
                }
                Rectangle {
                    id: nub
                    anchors.left: body.right
                    anchors.verticalCenter: body.verticalCenter
                    width: Math.max(2, Math.round(body.height / 5))
                    height: Math.round(body.height / 2)
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.6)
                }
            }

            PlasmaComponents.Label {
                visible: compact.indicator === "text" || Plasmoid.configuration.showPercent
                text: root.percentText
            }
        }
    }

    fullRepresentation: RowLayout {
        Layout.minimumWidth: implicitWidth
        Layout.minimumHeight: implicitHeight
        spacing: Kirigami.Units.largeSpacing

        BatteryRing {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 5
            Layout.preferredHeight: Kirigami.Units.gridUnit * 5
            percent: root.percent
            lineWidth: 6
            ringColor: root.levelColor

            ColumnLayout {
                spacing: 0

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: implicitWidth
                    source: Plasmoid.configuration.iconName
                }
                PlasmaComponents.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.percentText
                    font.bold: true
                    font.pixelSize: Kirigami.Units.gridUnit
                }
            }
        }

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Heading {
                level: 3
                text: "Zowie EC-CW"
            }
            PlasmaComponents.Label {
                text: root.tr("Battery") + ": " + root.percentText + (root.linked ? " (" + root.status.battery_mv + " " + root.tr("mV") + ", " + root.tr("mouse") + ": " + root.status.battery_percent + "%)" : "")
            }
            PlasmaComponents.Label {
                text: root.tr("Polling rate") + ": " + root.rateText
            }
            PlasmaComponents.Label {
                text: root.tr("Connection") + ": " + root.modeText
            }
            PlasmaComponents.Label {
                visible: root.status.battery_updated !== undefined
                opacity: 0.6
                text: root.tr("Updated") + ": " + new Date(root.status.battery_updated * 1000).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
            }
        }
    }
}
