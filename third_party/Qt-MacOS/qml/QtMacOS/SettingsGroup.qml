import QtQuick
import QtMacOS

Rectangle {
    id: group
    default property alias rows: rowColumn.data
    property int padding: 16
    property int horizontalPadding: padding
    property int verticalPadding: padding
    implicitWidth: 500
    implicitHeight: rowColumn.implicitHeight + 2 * verticalPadding
    radius: 10
    color: Theme.settingsGroup
    Column {
        id: rowColumn
        x: group.horizontalPadding
        y: group.verticalPadding
        width: Math.max(0, group.width - 2 * group.horizontalPadding)
    }
}
