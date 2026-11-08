pragma ComponentBehavior: Bound
import QtQuick
import QtMacOS

// A small related group, with its optional title above the quiet surface.
Item {
    id: box
    default property alias content: contents.data
    property string title: ""
    property real padding: 16
    property real spacing: 10
    property real titleSpacing: 8
    readonly property alias contentItem: contents

    implicitWidth: 320
    implicitHeight: (box.title.length > 0 ? heading.implicitHeight + titleSpacing : 0) + contents.implicitHeight + 2 * padding
    Accessible.role: Accessible.Grouping
    Accessible.name: title

    data: [
        MacLabel {
            id: heading
            width: box.width
            text: box.title
            role: MacLabel.Heading
            visible: text.length > 0
        },
        Rectangle {
            x: 0
            y: box.title.length > 0 ? heading.height + box.titleSpacing : 0
            width: box.width
            height: contents.implicitHeight + 2 * box.padding
            color: Theme.settingsGroup
            radius: 8
            Column {
                id: contents
                x: box.padding
                y: box.padding
                width: Math.max(0, box.width - 2 * box.padding)
                spacing: box.spacing
            }
        }
    ]
}
