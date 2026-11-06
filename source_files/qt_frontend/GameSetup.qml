// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "prototype"

GridLayout {
    id: setup
    property var tokens: null
    columns: width > 1000 ? 5 : width > 620 ? 3 : 2
    columnSpacing: 16
    rowSpacing: 14
    enabled: !backend.busy && !backend.loading
    function indexOf(items, value) {
        for (let i = 0; i < items.length; ++i)
            if (items[i].id === value)
                return i;
        return -1;
    }
    Repeater {
        model: [
            {
                key: "engine",
                text: "Движок"
            },
            {
                key: "game",
                text: "Игра"
            },
            {
                key: "port",
                text: "Порт"
            },
            {
                key: "length",
                text: "Длина"
            },
            {
                key: "theme",
                text: "Тема мира"
            }
        ]
        ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            Layout.minimumWidth: 110
            Label {
                text: modelData.text
                font: setup.tokens ? setup.tokens.captionFont : Qt.application.font
                color: setup.tokens ? setup.tokens.secondary : palette.windowText
                opacity: setup.tokens ? 1 : .7
            }
            PreviewComboBox {
                tokens: setup.tokens
                objectName: "gameChoice_" + modelData.key
                Layout.fillWidth: true
                model: backend.schema.choices ? backend.schema.choices[modelData.key] : []
                textRole: "text"
                valueRole: "id"
                currentIndex: {
                    backend.revision;
                    return setup.indexOf(model || [], backend.value("", modelData.key));
                }
                Accessible.name: modelData.text
                onActivated: backend.setGeneral(modelData.key, currentValue)
            }
        }
    }
}
