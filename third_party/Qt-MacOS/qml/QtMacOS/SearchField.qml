import QtQuick
import QtMacOS

MacTextField {
    id: field
    placeholderText: qsTr("Search")
    Accessible.name: qsTr("Search")
    selectByMouse: true
    inputMethodHints: Qt.ImhNoPredictiveText
}
