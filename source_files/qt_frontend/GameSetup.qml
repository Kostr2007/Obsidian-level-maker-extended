// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GridLayout {
    id: setup
    columns: width > 1000 ? 5 : width > 620 ? 3 : 2
    columnSpacing: 16
    enabled: !backend.busy && !backend.loading
    function indexOf(items, value) {
        for (let i = 0; i < items.length; ++i) if (items[i].id === value) return i
        return -1
    }
    Repeater {
        model: [{key:"engine",text:"Движок"},{key:"game",text:"Игра"},
            {key:"port",text:"Порт"},{key:"length",text:"Длина"},{key:"theme",text:"Тема мира"}]
        ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            Layout.minimumWidth: 110
            Label { text: modelData.text; font.pixelSize: 12; opacity: .7 }
            ComboBox {
                Layout.fillWidth: true
                model: backend.schema.choices ? backend.schema.choices[modelData.key] : []
                textRole: "text"; valueRole: "id"
                currentIndex: { backend.revision; return setup.indexOf(model || [], backend.value("",modelData.key)) }
                Accessible.name: modelData.text
                onActivated: backend.setGeneral(modelData.key,currentValue)
            }
        }
    }
}
