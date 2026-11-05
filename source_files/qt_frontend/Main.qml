// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Obsidian 1.0

ApplicationWindow {
    id: window
    width: Math.max(900, Math.min(1440, Screen.desktopAvailableWidth - 32))
    height: Math.max(480, Math.min(900, Screen.desktopAvailableHeight - 60))
    minimumWidth: 900
    minimumHeight: 480
    visible: true
    title: "Obsidian Extended · Studio"
    font.family: "DejaVu Sans"
    font.pixelSize: 13
    palette.window: backend.dark ? "#191d25" : "#f2f4f8"
    palette.windowText: backend.dark ? "#e4e9f2" : "#253047"
    palette.base: backend.dark ? "#171c24" : "#ffffff"
    palette.alternateBase: backend.dark ? "#2a3341" : "#e8edf5"
    palette.text: backend.dark ? "#e4e9f2" : "#253047"
    palette.button: backend.dark ? "#262d39" : "#f6f8fb"
    palette.buttonText: backend.dark ? "#e4e9f2" : "#253047"
    palette.mid: backend.dark ? "#414d60" : "#c4cedd"
    palette.dark: backend.dark ? "#0e121a" : "#bac4d2"
    palette.light: backend.dark ? "#48546a" : "#ffffff"
    palette.placeholderText: backend.dark ? "#8f9caf" : "#64748a"
    palette.highlight: backend.accent
    palette.highlightedText: "#101827"
    palette.toolTipBase: backend.dark ? "#262d39" : "#f6f8fb"
    palette.toolTipText: backend.dark ? "#e4e9f2" : "#253047"
    color: palette.window
    property string section: "geometry"
    property bool wide: width >= 1200
    property bool quitting: false
    property string query: ""
    onQueryChanged: {
        if (query.trim()) {
            let groups = selectedModules(false);
            if (groups.length && groups[0].options.length)
                inspect(groups[0].options[0], groups[0], false);
        }
    }
    property bool advanced: false
    property var inspected: null
    property string inspectedModule: ""
    property string inspectedModuleTitle: ""
    readonly property var categories: [
        {
            key: "project",
            text: "Игра и формат",
            hint: "Игра, порт, длительность и формат результата",
            number: "01"
        },
        {
            key: "geometry",
            text: "Геометрия",
            hint: "Масштаб уровня, помещения и переходы",
            number: "02"
        },
        {
            key: "combat",
            text: "Бой",
            hint: "Противники, сложность и засады",
            number: "03"
        },
        {
            key: "resources",
            text: "Ресурсы",
            hint: "Оружие, боеприпасы, лечение и секреты",
            number: "04"
        },
        {
            key: "appearance",
            text: "Оформление",
            hint: "Освещение, декорации и атмосфера",
            number: "05"
        },
        {
            key: "extensions",
            text: "Дополнения",
            hint: "Специальные режимы и подключённые модули",
            number: "06"
        }
    ]
    readonly property bool editing: categories.some(function (c) {
        return c.key === section;
    })
    function titleFor(key) {
        for (let c of categories)
            if (c.key === key)
                return c.text;
        return {
            preview: "Результат",
            log: "Журнал",
            settings: "Интерфейс"
        }[key] || "Studio";
    }
    function hintFor(key) {
        for (let c of categories)
            if (c.key === key)
                return c.hint;
        return "Obsidian Extended / Studio";
    }
    function choose(key) {
        section = key;
        query = "";
        optionsScroll.contentItem.contentY = 0;
    }
    function indexOf(items, value) {
        for (let i = 0; i < items.length; i++)
            if (items[i].id === value)
                return i;
        return -1;
    }
    function choiceText(key) {
        let items = backend.schema.choices ? backend.schema.choices[key] : [];
        let index = indexOf(items, backend.value("", key));
        return index < 0 ? "" : items[index].text;
    }
    function inspect(option, module, openPanel) {
        inspected = option;
        inspectedModule = module.id;
        inspectedModuleTitle = module.title;
        if (openPanel && !wide)
            inspectorDialog.open();
    }
    function refreshInspection() {
        let modules = backend.schema.modules || [];
        let chosen = null, owner = null;
        for (let m of modules) {
            if (!m.available)
                continue;
            for (let o of m.options) {
                if (o.kind === "header")
                    continue;
                if (m.id === inspectedModule && inspected && o.id === inspected.id) {
                    inspect(o, m, false);
                    return;
                }
                if (m.id === "ui_arch" && o.id === "float_size") {
                    chosen = o;
                    owner = m;
                }
            }
        }
        inspected = chosen;
        inspectedModule = owner ? owner.id : "";
        inspectedModuleTitle = owner ? owner.title : "";
    }
    function matches(m, o, q) {
        return [m.title, m.text, m.id, o.title, o.text, o.id, o.summary].join(" ").toLocaleLowerCase().includes(q);
    }
    function selectedModules(includeAdvanced) {
        let q = query.trim().toLocaleLowerCase(), result = [];
        for (let m of (backend.schema.modules || [])) {
            if (!m.available)
                continue;
            let opts = m.options.filter(function (o) {
                if (o.kind === "header")
                    return false;
                if (q)
                    return matches(m, o, q);
                return o.category === section && (includeAdvanced || advanced || !o.advanced);
            });
            let noOptions = m.options.length === 0 && (q ? (m.title + " " + m.text + " " + m.id).toLocaleLowerCase().includes(q) : m.category === section);
            if (opts.length || noOptions)
                result.push({
                    id: m.id,
                    text: m.text,
                    title: m.title,
                    tooltip: m.tooltip,
                    isUi: m.isUi,
                    enabled: m.enabled,
                    category: m.category,
                    options: opts
                });
        }
        return result;
    }
    function optionCount(includeAdvanced) {
        let n = 0;
        for (let m of selectedModules(includeAdvanced))
            n += m.options.length;
        return n;
    }
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            if (!window.editing)
                window.section = "geometry";
            search.forceActiveFocus();
        }
    }
    Shortcut {
        sequence: "Ctrl+G"
        onActivated: gameDialog.open()
    }
    Shortcut {
        sequence: "Ctrl+I"
        onActivated: inspectorDialog.open()
    }
    Shortcut {
        sequence: "F2"
        onActivated: {
            createAction.forceActiveFocus();
            Qt.callLater(function () {
                backend.generate();
            });
        }
    }
    Shortcut {
        sequence: "Alt+1"
        onActivated: window.choose("geometry")
    }
    Shortcut {
        sequence: "Alt+2"
        onActivated: window.choose("combat")
    }
    Shortcut {
        sequence: "Alt+3"
        onActivated: window.choose("resources")
    }
    Shortcut {
        sequence: "Alt+4"
        onActivated: window.choose("preview")
    }
    Shortcut {
        sequence: "Alt+5"
        onActivated: window.choose("log")
    }
    Shortcut {
        sequence: "Alt+6"
        onActivated: window.choose("settings")
    }
    Shortcut {
        sequence: StandardKey.Quit
        onActivated: window.close()
    }
    onClosing: function (close) {
        if (backend.busy) {
            close.accepted = false;
            exitDialog.open();
        }
    }
    Connections {
        target: backend
        function onSchemaChanged() {
            window.refreshInspection();
        }
        function onGenerationFinished(success) {
            if (window.quitting)
                Qt.quit();
        }
    }
    Dialog {
        id: exitDialog
        title: "Отменить генерацию и выйти?"
        anchors.centerIn: Overlay.overlay
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            window.quitting = true;
            backend.cancel();
        }
        Label {
            text: "Готовые результаты останутся в своих папках."
        }
    }
    Dialog {
        id: gameDialog
        title: "Игра и формат"
        anchors.centerIn: Overlay.overlay
        width: Math.min(720, window.width - 40)
        height: Math.min(400, window.height - 40)
        modal: true
        standardButtons: Dialog.Ok
        contentItem: ScrollView {
            id: gameScroll
            contentWidth: availableWidth
            clip: true
            GameSetup {
                width: gameScroll.availableWidth
            }
        }
    }
    Dialog {
        id: inspectorDialog
        title: "Пояснение параметра"
        anchors.centerIn: Overlay.overlay
        width: Math.min(600, window.width - 40)
        height: window.height - 60
        modal: true
        standardButtons: Dialog.Close
        contentItem: StudioInspector {
            option: window.inspected
            moduleId: window.inspectedModule
            moduleTitle: window.inspectedModuleTitle
            showPreview: false
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
    FolderDialog {
        id: outputDialog
        title: "Папка для новых карт"
        onAccepted: backend.chooseOutput(selectedFolder)
    }
    header: ToolBar {
        padding: 10
        implicitHeight: 56
        background: Rectangle {
            color: backend.dark ? "#20252e" : "#ffffff"
            border.color: window.palette.mid
        }
        contentItem: RowLayout {
            spacing: 16
            Label {
                text: "OBSIDIAN"
                font.pixelSize: 18
                font.weight: Font.Bold
                font.letterSpacing: 1.5
            }
            Label {
                text: "STUDIO"
                color: backend.accent
                font.pixelSize: 11
                font.letterSpacing: 2
            }
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 22
                color: window.palette.mid
            }
            Label {
                text: {
                    backend.schema;
                    backend.revision;
                    return window.choiceText("game") + "  /  " + window.choiceText("port");
                }
                Layout.fillWidth: true
                elide: Text.ElideRight
                opacity: .7
            }
            ActionButton {
                text: "Игра…"
                onClicked: gameDialog.open()
                enabled: !backend.loading && !backend.busy
            }
            ActionButton {
                text: backend.dark ? "Светлая тема" : "Тёмная тема"
                onClicked: backend.dark = !backend.dark
            }
        }
    }
    footer: ToolBar {
        padding: 12
        implicitHeight: 96
        background: Rectangle {
            color: backend.dark ? "#20252e" : "#ffffff"
            border.color: window.palette.mid
        }
        contentItem: ColumnLayout {
            spacing: 6
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Label {
                    text: "SEED"
                    font.pixelSize: 10
                    opacity: .65
                }
                TextField {
                    Layout.preferredWidth: window.width < 1100 ? 140 : 200
                    enabled: !backend.busy && !backend.loading
                    placeholderText: "0 — случайный"
                    text: {
                        backend.revision;
                        return backend.value("", "seed");
                    }
                    selectByMouse: true
                    maximumLength: 64
                    Accessible.name: "Seed генерации"
                    onEditingFinished: backend.setGeneral("seed", text)
                }
                ToolButton {
                    text: "↻"
                    enabled: !backend.busy && !backend.loading
                    Accessible.name: "Случайный seed"
                    onClicked: backend.setGeneral("seed", "0")
                }
                Label {
                    text: backend.outputFolder
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                    opacity: .65
                    font.pixelSize: 11
                }
                ActionButton {
                    text: "Папка…"
                    enabled: !backend.busy
                    onClicked: outputDialog.open()
                }
                ActionButton {
                    text: "Отмена"
                    visible: backend.busy
                    onClicked: backend.cancel()
                }
                ActionButton {
                    id: createAction
                    text: "Создать карту  ·  F2"
                    highlighted: true
                    enabled: !backend.busy && !backend.loading && !!backend.schema.protocol
                    onClicked: backend.generate()
                }
            }
            ProgressBar {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                value: backend.progress
                indeterminate: backend.loading || (backend.busy && backend.progress === 0)
            }
            Label {
                text: backend.status
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: 11
            }
        }
    }
    RowLayout {
        anchors.fill: parent
        spacing: 0
        Pane {
            Layout.preferredWidth: 190
            Layout.fillHeight: true
            padding: 12
            background: Rectangle {
                color: backend.dark ? "#161b23" : "#e9eef5"
            }
            ColumnLayout {
                anchors.fill: parent
                spacing: 6
                Label {
                    text: "ПАРАМЕТРЫ КАРТЫ"
                    font.pixelSize: 10
                    opacity: .5
                    Layout.topMargin: 8
                    Layout.bottomMargin: 12
                }
                ScrollView {
                    id: navScroll
                    ScrollBar.vertical.active: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    contentWidth: availableWidth
                    clip: true
                    ColumnLayout {
                        width: navScroll.availableWidth
                        spacing: 4
                        Repeater {
                            model: window.categories.concat([
                                {
                                    key: "preview",
                                    text: "Результат",
                                    number: "◇"
                                },
                                {
                                    key: "log",
                                    text: "Журнал",
                                    number: "≡"
                                },
                                {
                                    key: "settings",
                                    text: "Интерфейс",
                                    number: "⚙"
                                }
                            ])
                            ItemDelegate {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                text: modelData.text
                                highlighted: window.section === modelData.key
                                Accessible.name: modelData.text
                                onClicked: window.choose(modelData.key)
                                contentItem: RowLayout {
                                    Label {
                                        text: modelData.number
                                        font.pixelSize: 10
                                        opacity: .5
                                        Layout.preferredWidth: 22
                                    }
                                    Label {
                                        text: modelData.text
                                        Layout.fillWidth: true
                                        font.weight: window.section === modelData.key ? Font.DemiBold : Font.Normal
                                    }
                                }
                                background: Rectangle {
                                    radius: 4
                                    color: window.section === modelData.key ? (backend.dark ? "#28384f" : "#d7e4f7") : "transparent"
                                }
                            }
                        }
                    }
                }
                ActionButton {
                    text: "Импорт пресета"
                    Layout.fillWidth: true
                    enabled: !backend.busy && !backend.loading
                    onClicked: loadConfig.open()
                }
                ActionButton {
                    text: "Сохранить пресет"
                    Layout.fillWidth: true
                    enabled: !backend.busy && !backend.loading
                    onClicked: saveConfig.open()
                }
                Label {
                    text: "Studio / " + Qt.application.version
                    font.pixelSize: 10
                    opacity: .45
                    Layout.topMargin: 8
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 14
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        text: window.query.trim() ? "Результаты поиска" : window.titleFor(window.section)
                        font.pixelSize: 25
                        font.weight: Font.DemiBold
                    }
                    Label {
                        text: window.query.trim() ? "По всем разделам, включая расширенные параметры" : window.hintFor(window.section)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        opacity: .6
                        font.pixelSize: 12
                    }
                }
                ActionButton {
                    visible: window.editing && !window.wide
                    text: "Пояснение  ·  Ctrl+I"
                    onClicked: inspectorDialog.open()
                }
                BusyIndicator {
                    running: backend.loading
                    visible: running
                    implicitWidth: 28
                    implicitHeight: 28
                }
            }
            RowLayout {
                visible: window.editing
                Layout.fillWidth: true
                TextField {
                    id: search
                    objectName: "parameterSearch"
                    Layout.fillWidth: true
                    placeholderText: "Найти параметр во всех разделах…  Ctrl+F"
                    text: window.query
                    selectByMouse: true
                    onTextEdited: {
                        window.query = text;
                        // Replacing matching delegates can otherwise transfer focus
                        // to a newly-created editor while the user is still typing.
                        forceActiveFocus();
                    }
                    Accessible.name: "Поиск параметров"
                }
                ToolButton {
                    text: "×"
                    Accessible.name: "Очистить поиск"
                    enabled: window.query.length > 0
                    onClicked: window.query = ""
                }
                CheckBox {
                    text: "Расширенные"
                    checked: window.advanced
                    onToggled: window.advanced = checked
                    ToolTip.visible: hovered
                    ToolTip.text: "Все параметры, включая дополнительные модули"
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 20
                ScrollView {
                    id: optionsScroll
                    ScrollBar.vertical.active: true
                    visible: window.editing
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    clip: true
                    ColumnLayout {
                        width: optionsScroll.availableWidth
                        spacing: 14
                        Surface {
                            visible: window.section === "project" && !window.query
                            Layout.fillWidth: true
                            padding: 16
                            contentItem: GameSetup {}
                        }
                        Surface {
                            visible: window.section === "extensions" && !window.query
                            Layout.fillWidth: true
                            padding: 16
                            ColumnLayout {
                                anchors.fill: parent
                                Label {
                                    text: "Подключённые дополнения"
                                    font.weight: Font.DemiBold
                                }
                                Label {
                                    text: {
                                        backend.outputFolder;
                                        backend.schema;
                                        return backend.addons().join("\n") || "Дополнения не подключены";
                                    }
                                    Layout.fillWidth: true
                                    wrapMode: Text.WrapAnywhere
                                    opacity: .65
                                }
                                RowLayout {
                                    enabled: !backend.busy && !backend.loading
                                    ActionButton {
                                        text: "Подключить…"
                                        onClicked: addonDialog.open()
                                    }
                                    ActionButton {
                                        text: "Отключить все"
                                        onClicked: backend.clearAddons()
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: window.selectedModules(false)
                            Surface {
                                id: card
                                required property var modelData
                                property bool expanded: true
                                Layout.fillWidth: true
                                padding: 16
                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 10
                                    RowLayout {
                                        Layout.fillWidth: true
                                        CheckBox {
                                            visible: !card.modelData.isUi
                                            checked: card.modelData.enabled
                                            enabled: !backend.loading && !backend.busy
                                            Accessible.name: "Включить модуль " + card.modelData.title
                                            onToggled: backend.setModuleEnabled(card.modelData.id, checked)
                                        }
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3
                                            Label {
                                                text: card.modelData.title
                                                font.pixelSize: 16
                                                font.weight: Font.DemiBold
                                                Layout.fillWidth: true
                                                wrapMode: Text.WordWrap
                                            }
                                            Label {
                                                visible: !!window.query
                                                text: card.modelData.options.length ? window.titleFor(card.modelData.options[0].category) : window.titleFor(card.modelData.category)
                                                font.pixelSize: 10
                                                opacity: .6
                                            }
                                        }
                                        ToolButton {
                                            text: card.expanded ? "−" : "+"
                                            Accessible.name: "Свернуть или раскрыть " + card.modelData.title
                                            onClicked: card.expanded = !card.expanded
                                        }
                                    }
                                    Label {
                                        visible: !card.modelData.isUi && !card.modelData.enabled
                                        text: "Включите модуль, чтобы применить его настройки."
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                        opacity: .6
                                        font.pixelSize: 12
                                    }
                                    ColumnLayout {
                                        visible: card.expanded
                                        Layout.fillWidth: true
                                        spacing: 14
                                        Repeater {
                                            model: card.modelData.options
                                            OptionEditor {
                                                required property var modelData
                                                option: modelData
                                                moduleId: card.modelData.id
                                                writable: (card.modelData.isUi || card.modelData.enabled) && !backend.busy && !backend.loading
                                                onExplain: function (openPanel) {
                                                    window.inspect(modelData, card.modelData, openPanel);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Label {
                            visible: window.selectedModules(false).length === 0
                            text: backend.loading ? "Получаем настройки…" : window.query ? "Ничего не найдено. Попробуйте название или ID параметра." : "Основных параметров здесь нет. Включите расширенные настройки."
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            padding: 16
                            opacity: .7
                        }
                        ActionButton {
                            visible: !window.advanced && !window.query && window.optionCount(true) > window.optionCount(false)
                            text: "Ещё параметров: " + (window.optionCount(true) - window.optionCount(false)) + "  ·  Показать расширенные"
                            Layout.fillWidth: true
                            onClicked: window.advanced = true
                        }
                    }
                }
                Surface {
                    visible: window.editing && window.wide
                    Layout.preferredWidth: 312
                    Layout.fillHeight: true
                    padding: 16
                    contentItem: ColumnLayout {
                        spacing: 12
                        StudioInspector {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            option: window.inspected
                            moduleId: window.inspectedModule
                            moduleTitle: window.inspectedModuleTitle
                            showPreview: false
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: window.palette.mid
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "ПОСЛЕДНИЙ РЕЗУЛЬТАТ"
                                font.pixelSize: 10
                                opacity: .6
                                Layout.fillWidth: true
                            }
                            ToolButton {
                                text: "↗"
                                Accessible.name: "Открыть результат"
                                onClicked: window.choose("preview")
                            }
                        }
                        WadView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            file: backend.previewFile
                        }
                    }
                }
                Surface {
                    visible: window.section === "preview"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: 16
                    ColumnLayout {
                        anchors.fill: parent
                        Label {
                            text: "Геометрия из созданного WAD"
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        WadView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            file: backend.previewFile
                        }
                        Label {
                            text: backend.resultFolder
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                            font.pixelSize: 12
                        }
                        Label {
                            visible: !!backend.resultFolder && !backend.previewFile
                            text: "Формат сохранён без предпросмотра. Откройте папку результата."
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                        ActionButton {
                            text: "Открыть папку результата"
                            enabled: !!backend.resultFolder
                            onClicked: backend.openResult()
                        }
                    }
                }
                ScrollView {
                    visible: window.section === "log"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    TextArea {
                        text: backend.log
                        readOnly: true
                        selectByMouse: true
                        wrapMode: TextEdit.Wrap
                        font.family: "monospace"
                        font.pixelSize: 12
                    }
                }
                ScrollView {
                    id: settingsScroll
                    ScrollBar.vertical.active: true
                    visible: window.section === "settings"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: availableWidth
                    clip: true
                    ColumnLayout {
                        width: settingsScroll.availableWidth
                        spacing: 16
                        Label {
                            text: "Studio / рабочее пространство"
                            font.pixelSize: 20
                        }
                        Label {
                            text: "Категории слева, настройки в центре, пояснения справа.\nНа небольшом экране справка доступна по Ctrl+I или кнопке «?»."
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: .7
                        }
                        Switch {
                            text: "Тёмное оформление"
                            checked: backend.dark
                            onToggled: backend.dark = checked
                        }
                        Label {
                            text: "Акцент"
                            font.weight: Font.DemiBold
                        }
                        RowLayout {
                            Repeater {
                                model: [
                                    {
                                        color: "#72a7ff",
                                        text: "Синий"
                                    },
                                    {
                                        color: "#81c7ad",
                                        text: "Зелёный"
                                    },
                                    {
                                        color: "#c1a1e6",
                                        text: "Сиреневый"
                                    },
                                    {
                                        color: "#e6bc86",
                                        text: "Песочный"
                                    }
                                ]
                                ActionButton {
                                    required property var modelData
                                    text: modelData.text
                                    highlighted: backend.accent === modelData.color
                                    onClicked: backend.accent = modelData.color
                                }
                            }
                        }
                        ActionButton {
                            text: "Обновить параметры генератора"
                            enabled: !backend.busy && !backend.loading
                            onClicked: backend.reload()
                        }
                        Label {
                            text: "F2 — создать карту\nCtrl+F — поиск по всем параметрам\nCtrl+G — игра и формат\nCtrl+I — пояснение параметра\nAlt+1…6 — геометрия, бой, ресурсы, результат, журнал, интерфейс"
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            opacity: .7
                        }
                    }
                }
            }
        }
    }
}
