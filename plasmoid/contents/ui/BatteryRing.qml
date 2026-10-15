import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

Item {
    id: ring

    property real percent: 0
    property real lineWidth: 4
    property color ringColor: Kirigami.Theme.positiveTextColor
    default property alias content: center.data

    readonly property real arcRadius: Math.min(width, height) / 2 - lineWidth / 2

    Shape {
        anchors.fill: parent
        visible: ring.lineWidth > 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Qt.alpha(Kirigami.Theme.textColor, 0.15)
            strokeWidth: ring.lineWidth
            fillColor: "transparent"
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.arcRadius
                radiusY: ring.arcRadius
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: ring.ringColor
            strokeWidth: ring.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.arcRadius
                radiusY: ring.arcRadius
                startAngle: -90
                sweepAngle: 360 * Math.max(0, Math.min(ring.percent, 100)) / 100
            }
        }
    }

    Item {
        id: center
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }
}
