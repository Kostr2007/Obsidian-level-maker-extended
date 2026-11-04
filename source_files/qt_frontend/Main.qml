// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import Obsidian 1.0

ApplicationWindow {
    id: window
    width: Math.max(900, Math.min(1440, Screen.desktopAvailableWidth - 32))
    height: Math.max(480, Math.min(900, Screen.desktopAvailableHeight - 60))
    minimumWidth: 900; minimumHeight: 480
    visible: true
    title: "Obsidian Extended · Qt 6"
    Material.theme: backend.dark ? Material.Dark : Material.Light
    Material.accent: backend.accent
    Material.background: backend.dark ? "#10181c" : "#f8faf9"
    Material.foreground: backend.dark ? "#e5edf0" : "#192325"
    property string section: "world"
    property bool wide: width >= 1260
    property bool quitting: false
    property string query: ""
    property bool setupExpanded: true
    function toggleSetup() {
        if (height < 720) gameDialog.open()
        else setupExpanded = !setupExpanded
    }
    function choiceText(key) {
        let items = backend.schema.choices ? backend.schema.choices[key] : []
        let index = indexOf(items, backend.value("", key))
        return index < 0 ? "" : items[index].text
    }
    color: Material.background
    function indexOf(items, value) {
        for (let i = 0; i < items.length; ++i) if (items[i].id === value) return i
        return -1
    }
    function selectedModules() {
        let modules = backend.schema.modules || []
        let q = query.toLocaleLowerCase()
        return modules.filter(function(m) {
            if (!m.available || m.group !== section) return false
            if (q.length === 0 || m.text.toLocaleLowerCase().includes(q)) return true
            return m.options.some(function(o) { return o.text.toLocaleLowerCase().includes(q) })
        })
    }
    Shortcut { sequence: "Ctrl+F"; onActivated: { if (window.section !== "world" && window.section !== "gameplay" && window.section !== "modules") window.section = "world"; search.forceActiveFocus() } }
    Shortcut { sequence: "Ctrl+G"; onActivated: window.toggleSetup() }
    Shortcut { sequence: "F2"; onActivated: { createAction.forceActiveFocus(); Qt.callLater(function() { backend.generate() }) } }
    Shortcut { sequence: "Alt+1"; onActivated: window.section = "world" }
    Shortcut { sequence: "Alt+2"; onActivated: window.section = "gameplay" }
    Shortcut { sequence: "Alt+3"; onActivated: window.section = "modules" }
    Shortcut { sequence: "Alt+4"; onActivated: window.section = "preview" }
    Shortcut { sequence: "Alt+5"; onActivated: window.section = "log" }
    Shortcut { sequence: "Alt+6"; onActivated: window.section = "settings" }
    Shortcut { sequence: StandardKey.Quit; onActivated: window.close() }
    onClosing: function(close) {
        if (backend.busy) { close.accepted = false; exitDialog.open() }
    }
    Connections {
        target: backend
        function onGenerationFinished(success) {
            if (window.quitting) Qt.quit()
        }
    }
    Dialog {
        id: exitDialog
        title: "Отменить генерацию и выйти?"
        anchors.centerIn: Overlay.overlay
        modal: true
        Overlay.modal: Rectangle { color: "#99000000" }
        standardButtons: Dialog.Yes | Dialog.No
        background: Rectangle { radius: 18; color: backend.dark ? "#253238" : "#eef4f1" }
        onAccepted: { window.quitting = true; backend.cancel() }
        Label { text: "Готовые результаты останутся в своих папках."; padding: 16 }
    }
    Dialog {
        id: gameDialog
        title: "Параметры игры"
        anchors.centerIn: Overlay.overlay
        width: Math.min(720, Overlay.overlay.width - 40)
        height: Math.min(440, Overlay.overlay.height - 40)
        modal: true
        Overlay.modal: Rectangle { color: "#99000000" }
        standardButtons: Dialog.Ok
        background: Rectangle { radius: 18; color: backend.dark ? "#253238" : "#eef4f1" }
        contentItem: ScrollView {
            id: gameScroll
            contentWidth: availableWidth
            clip: true
            GameSetup { width: gameScroll.availableWidth }
        }
    }
    FileDialog {
        id: loadConfig
        title: "Импорт конфигурации OBSIDIAN"
        nameFilters: ["Конфигурации (*.txt *.cfg)", "Все файлы (*)"]
        onAccepted: backend.importConfig(selectedFile)
    }
    FileDialog {
        id: saveConfig
        title: "Экспорт конфигурации OBSIDIAN"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "txt"
        nameFilters: ["Конфигурации (*.txt)"]
        onAccepted: backend.exportConfig(selectedFile)
    }
    FileDialog {
        id: addonDialog
        title: "Подключить дополнение"
        nameFilters: ["Дополнения (*.pk3 *.pk7 *.wad *.zip)", "Все файлы (*)"]
        onAccepted: backend.addAddon(selectedFile)
    }
    FolderDialog { id: outputDialog; title: "Папка для новых карт"; onAccepted: backend.chooseOutput(selectedFolder) }
    ButtonGroup { id: navigationGroup; exclusive: true }
    RowLayout {
        anchors.fill: parent
        spacing: 0
        Pane {
            Layout.preferredWidth: 216
            Layout.fillHeight: true
            padding: 16
            background: Rectangle { color: backend.dark ? "#172126" : "#e9f0ee" }
            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                Label { text: "OBSIDIAN"; font.pixelSize: 21; font.weight: Font.Bold; Layout.topMargin: 12 }
                Label { text: "LEVEL MAKER / QT 6"; font.pixelSize: 11; opacity: .6; Layout.bottomMargin: 26 }
                ScrollView {
                    id: navigationScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    contentWidth: availableWidth
                    clip: true
                    ScrollBar.vertical.active: true
                    ColumnLayout {
                        width: navigationScroll.availableWidth
                        spacing: window.height < 720 ? 4 : 8
                Repeater {
                    model: [ {key:"world",text:"Мир"}, {key:"gameplay",text:"Бой и предметы"},
                        {key:"modules",text:"Модули"}, {key:"preview",text:"Результат"},
                        {key:"log",text:"Журнал"}, {key:"settings",text:"Настройки"} ]
                    ActionButton {
                        required property var modelData
                        ButtonGroup.group: navigationGroup
                        Layout.preferredHeight: window.height < 720 ? 40 : 56
                        topInset: window.height < 720 ? 0 : 6
                        bottomInset: window.height < 720 ? 0 : 6
                        Layout.fillWidth: true
                        text: modelData.text
                        checkable: true
                        checked: window.section === modelData.key
                        highlighted: checked
                        flat: !checked
                        onClicked: window.section = modelData.key
                    }
                }
                    }
                }
                ActionButton { text: "Импорт пресета"; Layout.fillWidth: true; enabled: !backend.busy && !backend.loading; onClicked: loadConfig.open() }
                ActionButton { text: "Сохранить пресет"; Layout.fillWidth: true; enabled: !backend.busy && !backend.loading; onClicked: saveConfig.open() }
                Label { text: "Obsidian Extended " + Qt.application.version; opacity: .45; font.pixelSize: 11; Layout.topMargin: 12 }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.margins: 24
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Label { text: "Создайте мир, который запомнят"; font.pixelSize: 26; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Label { text: { backend.schema; backend.revision; return window.choiceText("game") + "  ·  " + window.choiceText("port") + "  ·  " + window.choiceText("length") }
                        opacity: .65; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
                ActionButton {
                    text: window.height < 720 || !window.setupExpanded ? "Выбрать игру" : "Скрыть параметры"
                    visible: ["world","gameplay","modules"].includes(window.section)
                    enabled: !backend.busy && !backend.loading
                    onClicked: window.toggleSetup()
                }
                BusyIndicator { running: backend.loading; visible: running; implicitWidth: 36; implicitHeight: 36 }
            }
            Surface {
                Layout.fillWidth: true
                visible: window.setupExpanded && window.height >= 720 && ["world","gameplay","modules"].includes(window.section)
                padding: 16
                contentItem: GameSetup { }
            }
            RowLayout {
                Layout.fillWidth: true
                visible: ["world","gameplay","modules"].includes(window.section)
                TextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: "Поиск параметров и модулей…  Ctrl+F"
                    text: window.query
                    selectByMouse: true
                    onTextEdited: window.query = text
                    Accessible.name: "Поиск параметров"
                }
                ToolButton { text: "✕"; enabled: search.text.length > 0; Accessible.name: "Очистить поиск"; onClicked: { window.query = ""; search.clear() } }
            }
            RowLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                spacing: 20
                ScrollView {
                    id: optionsScroll
                    Layout.fillWidth: true; Layout.fillHeight: true
                    visible: ["world","gameplay","modules"].includes(window.section)
                    clip: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        width: optionsScroll.availableWidth
                        spacing: 16
                        Repeater {
                            model: window.selectedModules()
                            Surface {
                                id: card
                                required property var modelData
                                property bool expanded: true
                                Layout.fillWidth: true
                                padding: 18
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true
                                        CheckBox {
                                            visible: !card.modelData.isUi
                                            checked: card.modelData.enabled
                                            enabled: !backend.loading && !backend.busy
                                            Accessible.name: "Включить модуль " + card.modelData.text
                                            onToggled: backend.setModuleEnabled(card.modelData.id, checked)
                                        }
                                        Label { text: card.modelData.text; font.pixelSize: 20; font.weight: Font.DemiBold; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                                        ToolButton { text: card.expanded ? "−" : "+"; Accessible.name: "Свернуть или раскрыть " + card.modelData.text; onClicked: card.expanded = !card.expanded }
                                    }
                                    Label {
                                        visible: card.modelData.tooltip.length > 0 && !card.modelData.isUi
                                        text: card.modelData.tooltip
                                        opacity: .65; wrapMode: Text.WordWrap; Layout.fillWidth: true
                                    }
                                    ColumnLayout {
                                        visible: card.expanded && (card.modelData.enabled || card.modelData.isUi)
                                        enabled: !backend.busy && !backend.loading
                                        Layout.fillWidth: true
                                        spacing: 12
                                        Repeater {
                                            model: card.modelData.options
                                            OptionEditor { required property var modelData; option: modelData; moduleId: card.modelData.id }
                                        }
                                    }
                                }
                            }
                        }
                        Label { visible: window.selectedModules().length === 0; text: backend.loading ? "Получаем настройки…" : "Ничего не найдено. Попробуйте другой запрос."; padding: 24; wrapMode: Text.WordWrap; Layout.fillWidth: true; opacity: .7 }
                    }
                }
                Surface {
                    visible: window.section === "preview" || (window.wide && ["world","gameplay","modules"].includes(window.section))
                    Layout.preferredWidth: window.section === "preview" ? -1 : 330
                    Layout.fillWidth: window.section === "preview"
                    Layout.fillHeight: true
                    padding: 16
                    ColumnLayout {
                        anchors.fill: parent
                        Label { text: "Ваша новая карта"; font.pixelSize: 20; font.weight: Font.DemiBold }
                        Label { text: "Геометрия из созданного WAD"; font.pixelSize: 12; opacity: .6 }
                        WadView { Layout.fillWidth: true; Layout.fillHeight: true; Layout.minimumHeight: 180; file: backend.previewFile }
                        Label { text: backend.resultFolder; visible: text.length > 0; elide: Text.ElideMiddle; Layout.fillWidth: true; font.pixelSize: 12 }
                        Label { visible: backend.resultFolder.length > 0 && backend.previewFile.length === 0; text: "Этот формат сохранён без предпросмотра. Откройте папку результата."; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                        ActionButton { text: "Открыть папку результата"; Layout.fillWidth: true; enabled: backend.resultFolder.length > 0; onClicked: backend.openResult() }
                    }
                }
                ScrollView {
                    id: logScroll
                    visible: window.section === "log"
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: availableWidth
                    TextArea { text: backend.log; readOnly: true; selectByMouse: true; wrapMode: TextEdit.Wrap; font.family: "monospace"; font.pixelSize: 12 }
                }
                ScrollView {
                    id: settingsScroll
                    visible: window.section === "settings"
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: availableWidth
                    ColumnLayout {
                        width: settingsScroll.availableWidth
                        spacing: 20
                        Label { text: "Под ваш стиль"; font.pixelSize: 24 }
                        Switch { text: "Тёмное оформление"; checked: backend.dark; onToggled: backend.dark = checked }
                        Label { text: "Акцент интерфейса"; font.pixelSize: 16 }
                        RowLayout {
                            Repeater {
                                model: [{color:"#80cbc4",text:"Мята"},{color:"#b39ddb",text:"Лаванда"},{color:"#90caf9",text:"Океан"},{color:"#ffcc80",text:"Песок"}]
                                ActionButton { required property var modelData; text: modelData.text; highlighted: backend.accent === modelData.color; onClicked: backend.accent = modelData.color }
                            }
                        }
                        Label { text: "Дополнения генератора"; font.pixelSize: 20; Layout.topMargin: 12 }
                        Label { text: { backend.outputFolder; backend.schema; return backend.addons().join("\n") || "Дополнения не подключены" }
                            wrapMode: Text.WrapAnywhere; Layout.fillWidth: true; opacity: .7 }
                        RowLayout {
                            enabled: !backend.busy && !backend.loading
                            ActionButton { text: "Подключить…"; onClicked: addonDialog.open() }
                            ActionButton { text: "Отключить все"; onClicked: backend.clearAddons() }
                            ActionButton { text: "Обновить настройки"; onClicked: backend.reload() }
                        }
                        Label { text: "Готовые карты сохраняются в отдельных папках.\nОтмена удаляет только незавершённую сборку. Конфигурации совместимы с OBSIDIAN."; Layout.fillWidth: true; wrapMode: Text.WordWrap; opacity: .6 }
                    }
                }
            }
            Surface {
                Layout.fillWidth: true
                padding: 14
                ColumnLayout {
                    anchors.fill: parent
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Seed"; opacity: .7 }
                        TextField {
                            Layout.preferredWidth: window.width < 1100 ? 145 : 200
                            enabled: !backend.busy && !backend.loading
                            placeholderText: "0 — случайный"
                            text: { backend.revision; return backend.value("","seed") }
                            selectByMouse: true
                            maximumLength: 64
                            Accessible.name: "Seed генерации"
                            onEditingFinished: backend.setGeneral("seed",text)
                        }
                        ToolButton { text: "↻"; enabled: !backend.busy && !backend.loading; Accessible.name: "Случайный seed"; ToolTip.visible: hovered; ToolTip.text: "Случайный seed при следующей генерации"; onClicked: backend.setGeneral("seed","0") }
                        Label { text: backend.outputFolder; Layout.fillWidth: true; elide: Text.ElideMiddle; opacity: .6; font.pixelSize: 12 }
                        ActionButton { text: "Папка…"; enabled: !backend.busy; onClicked: outputDialog.open() }
                        ActionButton { text: "Отмена"; visible: backend.busy; onClicked: backend.cancel() }
                        ActionButton { id: createAction; text: "Создать карту  ·  F2"; highlighted: true; enabled: !backend.busy && !backend.loading && !!backend.schema.protocol; onClicked: backend.generate() }
                    }
                    ProgressBar { Layout.fillWidth: true; value: backend.progress; indeterminate: backend.loading || (backend.busy && backend.progress === 0) }
                    Label { text: backend.status; Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12 }
                }
            }
        }
    }
}
