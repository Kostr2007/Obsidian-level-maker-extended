// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Obsidian 1.0
import ".."
import "../ResourceAssets.js" as Resources

ApplicationWindow {
    id: window
    width: Math.min(1440, Math.max(900, Screen.desktopAvailableWidth - 48))
    height: Math.min(900, Math.max(540, Screen.desktopAvailableHeight - 60))
    minimumWidth: 880
    minimumHeight: 520
    visible: true
    title: "Obsidian · Design Preview"
    font.family: Qt.application.font.family
    font.pixelSize: design.bodySize
    color: design.canvas
    palette.window: design.canvas
    palette.windowText: design.text
    palette.base: design.surface
    palette.text: design.text
    palette.button: design.surface
    palette.buttonText: design.text
    palette.alternateBase: design.hover
    palette.mid: design.line
    palette.highlight: design.accent
    palette.highlightedText: design.accentText
    palette.placeholderText: design.secondary
    DesignTokens {
        id: design
    }
    property string section: "resources"
    property string pendingSection: "resources"
    property string currentResourceId: "ammo"
    property string resourceViewMode: "grid"
    readonly property bool reduceMotion: design.reduceMotion
    readonly property bool motionActive: navigationMotion.running || sidebarMotion.running || inspectorMotion.running
    readonly property bool resourceGameCompatible: {
        backend.revision;
        backend.schema;
        return Resources.compatible(backend.value("", "game"));
    }
    property string query: ""
    property bool advanced: false
    property bool sidebarShown: true
    property bool inspectorShown: true
    readonly property bool inlineInspector: width >= 1200 && inspectorShown
    property var inspected: null
    property string inspectedModule: ""
    property bool quitting: false
    readonly property var categories: [
        {
            key: "project",
            title: "Игра и формат",
            icon: "project"
        },
        {
            key: "geometry",
            title: "Геометрия",
            icon: "geometry"
        },
        {
            key: "combat",
            title: "Бой",
            icon: "combat"
        },
        {
            key: "resources",
            title: "Ресурсы",
            icon: "resources"
        },
        {
            key: "appearance",
            title: "Оформление",
            icon: "appearance"
        },
        {
            key: "results",
            title: "Результат",
            icon: "results"
        }
    ]
    Component.onCompleted: selectInitial()
    function titleFor(key) {
        for (let c of categories)
            if (c.key === key)
                return c.title;
        return "Параметры";
    }
    function choiceText(key) {
        let list = backend.schema.choices ? backend.schema.choices[key] : [];
        let value = backend.value("", key);
        for (let c of list)
            if (c.id === value)
                return c.text;
        return "";
    }
    function modules() {
        let q = query.trim().toLocaleLowerCase(), result = [];
        for (let m of (backend.schema.modules || [])) {
            if (!m.available || !m.isUi)
                continue;
            let options = m.options.filter(function (o) {
                return o.kind !== "header" && (q ? [o.title, o.text, o.id, o.summary].join(" ").toLocaleLowerCase().includes(q) : o.category === section && (advanced || !o.advanced) && (section !== "resources" || o.id === currentResourceId));
            });
            if (options.length)
                result.push({
                    id: m.id,
                    title: m.title,
                    options: options
                });
        }
        return result;
    }
    function inspect(option, moduleId, openPanel) {
        inspected = option;
        inspectedModule = moduleId;
        if (openPanel && !inlineInspector)
            inspectorDialog.open();
    }
    function resourceEntries() {
        for (let m of (backend.schema.modules || [])) {
            if (m.id !== "ui_pickups" || !m.available)
                continue;
            let ordered = [];
            for (let id of ["ammo", "health", "items", "weapons", "secrets", "secrets_bonus"])
                for (let option of m.options)
                    if (option.id === id)
                        ordered.push(option);
            return ordered;
        }
        return [];
    }
    function selectResource(id, openPanel) {
        for (let option of resourceEntries())
            if (option.id === id) {
                currentResourceId = id;
                inspect(option, "ui_pickups", openPanel);
                return;
            }
    }
    function selectInitial() {
        inspected = null;
        inspectedModule = "";
        if (section === "resources") {
            selectResource(currentResourceId, false);
            return;
        }
        for (let m of (backend.schema.modules || []))
            if (m.available && m.isUi)
                for (let o of m.options)
                    if (o.category === section && o.kind !== "header") {
                        inspect(o, m.id, false);
                        return;
                    }
        inspected = null;
    }
    function finishNavigation() {
        if (section === "resources")
            resourceGallery.focusSelection();
    }
    function applyNavigation() {
        section = pendingSection;
        query = "";
        selectInitial();
        contentScroll.contentItem.contentY = 0;
    }
    function go(key) {
        if (navigationMotion.running)
            navigationMotion.complete();
        pendingSection = key;
        if (section === key || design.reduceMotion) {
            applyNavigation();
            Qt.callLater(finishNavigation);
        } else
            navigationMotion.start();
    }
    SequentialAnimation {
        id: navigationMotion
        NumberAnimation {
            target: pageContent
            property: "opacity"
            to: 0
            duration: design.navOut
        }
        ScriptAction {
            script: {
                window.applyNavigation();
                pageShift.y = 12;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: pageContent
                property: "opacity"
                to: 1
                duration: design.navIn
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: pageShift
                property: "y"
                to: 0
                duration: design.navIn
                easing.type: Easing.OutCubic
            }
        }
        onFinished: window.finishNavigation()
    }
    Connections {
        target: design
        function onReduceMotionChanged() {
            if (design.reduceMotion) {
                navigationMotion.complete();
                sidebarMotion.complete();
                inspectorMotion.complete();
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+1"
        onActivated: window.resourceViewMode = "grid"
    }
    Shortcut {
        sequence: "Ctrl+2"
        onActivated: window.resourceViewMode = "list"
    }
    Shortcut {
        sequence: "Ctrl+Shift+M"
        onActivated: design.reduceMotion = !design.reduceMotion
    }
    Shortcut {
        sequence: "Ctrl+Shift+B"
        onActivated: window.sidebarShown = !window.sidebarShown
    }
    function generate() {
        createButton.forceActiveFocus();
        Qt.callLater(function () {
            backend.generate();
        });
    }
    Shortcut {
        sequence: "F2"
        onActivated: window.generate()
    }
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            if (navigationMotion.running)
                navigationMotion.complete();
            if (window.section === "results")
                window.section = "combat";
            Qt.callLater(function () {
                search.forceActiveFocus();
            });
        }
    }
    Shortcut {
        sequence: "Ctrl++"
        onActivated: design.textScale = 1.25
    }
    Shortcut {
        sequence: "Ctrl+0"
        onActivated: design.textScale = 1
    }
    Shortcut {
        sequence: "Ctrl+G"
        onActivated: gameDialog.open()
    }
    Shortcut {
        sequence: "Ctrl+I"
        onActivated: {
            if (window.width < 1200)
                inspectorDialog.open();
            else
                window.inspectorShown = !window.inspectorShown;
        }
    }
    Shortcut {
        sequence: "Alt+1"
        onActivated: window.go("geometry")
    }
    Shortcut {
        sequence: "Alt+2"
        onActivated: window.go("combat")
    }
    Shortcut {
        sequence: "Alt+3"
        onActivated: window.go("resources")
    }
    Shortcut {
        sequence: "Alt+4"
        onActivated: window.go("results")
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
            window.selectInitial();
        }
        function onGenerationFinished(success) {
            if (window.quitting)
                Qt.quit();
        }
    }
    Menu {
        id: commands
        MenuItem {
            text: "Создать карту  ·  F2"
            enabled: createButton.enabled
            onTriggered: window.generate()
        }
        MenuItem {
            text: "Игра и формат…  ·  Ctrl+G"
            enabled: !backend.loading && !backend.busy
            onTriggered: gameDialog.open()
        }
        MenuSeparator {}
        MenuItem {
            text: "Импорт пресета…"
            enabled: !backend.loading && !backend.busy
            onTriggered: loadConfig.open()
        }
        MenuItem {
            text: "Сохранить пресет…"
            enabled: !backend.loading && !backend.busy
            onTriggered: saveConfig.open()
        }
        MenuItem {
            text: "Папка результатов…"
            enabled: !backend.busy
            onTriggered: outputDialog.open()
        }
        MenuSeparator {}
        MenuItem {
            text: "Боковая панель  ·  Ctrl+Shift+B"
            checkable: true
            checked: window.sidebarShown
            onTriggered: window.sidebarShown = checked
        }
        MenuItem {
            text: "Инспектор  ·  Ctrl+I"
            onTriggered: {
                if (window.width < 1200)
                    inspectorDialog.open();
                else
                    window.inspectorShown = !window.inspectorShown;
            }
        }
        MenuItem {
            text: "Тёмное оформление"
            checkable: true
            checked: backend.dark
            onTriggered: backend.dark = checked
        }
        MenuItem {
            text: "Увеличенный текст"
            checkable: true
            checked: design.textScale > 1
            onTriggered: design.textScale = checked ? 1.25 : 1
        }
        MenuItem {
            text: "Меньше анимации  ·  Ctrl+Shift+M"
            checkable: true
            checked: design.reduceMotion
            onTriggered: design.reduceMotion = checked
        }
        MenuSeparator {}
        MenuItem {
            text: "Выйти  ·  Ctrl+Q"
            onTriggered: window.close()
        }
    }
    FileDialog {
        id: loadConfig
        title: "Импорт конфигурации"
        nameFilters: ["Конфигурации (*.txt *.cfg)", "Все файлы (*)"]
        onAccepted: backend.importConfig(selectedFile)
    }
    FileDialog {
        id: saveConfig
        title: "Сохранить конфигурацию"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "txt"
        onAccepted: backend.exportConfig(selectedFile)
    }
    FolderDialog {
        id: outputDialog
        title: "Папка результатов"
        onAccepted: backend.chooseOutput(selectedFolder)
    }
    Dialog {
        id: gameDialog
        title: "Игра и формат"
        anchors.centerIn: Overlay.overlay
        modal: true
        width: Math.min(680, window.width - 48)
        height: Math.min(400, window.height - 48)
        standardButtons: Dialog.Ok
        contentItem: ScrollView {
            id: gameScroll
            contentWidth: availableWidth
            GameSetup {
                width: gameScroll.availableWidth
            }
        }
    }
    Dialog {
        id: exitDialog
        width: Math.min(440, window.width - 48)
        height: 180
        title: "Отменить генерацию и выйти?"
        anchors.centerIn: Overlay.overlay
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            window.quitting = true;
            backend.cancel();
        }
        Label {
            text: "Готовые результаты сохранятся."
        }
    }
    Dialog {
        id: inspectorDialog
        objectName: "inspectorDialog"
        title: "Пояснение параметра"
        anchors.centerIn: Overlay.overlay
        modal: true
        width: Math.min(620, window.width - 48)
        height: window.height - 64
        standardButtons: Dialog.Close
        contentItem: Loader {
            sourceComponent: inspectorContent
        }
    }
    Component {
        id: inspectorContent
        ScrollView {
            id: helpScroll
            rightPadding: 12
            contentWidth: availableWidth
            clip: true
            ScrollBar.vertical.active: true
            ColumnLayout {
                width: helpScroll.availableWidth
                spacing: 16
                Label {
                    text: "Об этом параметре"
                    font.pixelSize: design.smallSize
                    color: design.secondary
                }
                Label {
                    objectName: "resourceDetailTitle"
                    text: window.inspected ? window.inspected.title : "Выберите параметр"
                    font.pixelSize: Math.round(20 * design.textScale)
                    font.weight: Font.DemiBold
                    color: design.text
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                Label {
                    text: window.inspected ? (window.inspected.summary || window.inspected.tooltip) : "Нажмите «?» рядом с настройкой."
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: design.secondary
                    font.pixelSize: design.bodySize
                    lineHeight: 1.15
                }
                AssetPreview {
                    textScale: design.textScale
                    optionId: window.inspectedModule === "ui_pickups" && window.inspected ? window.inspected.id : ""
                    visible: available
                }
                GameplayComparison {
                    example: window.inspected ? window.inspected.comparison : ""
                    visible: supported
                }
                Label {
                    text: window.inspected ? window.inspected.related : ""
                    visible: !!text
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: design.secondary
                    font.pixelSize: design.smallSize
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: design.line
                }
                Label {
                    text: "Текущее значение"
                    font.pixelSize: design.smallSize
                    color: design.secondary
                }
                Label {
                    text: {
                        backend.revision;
                        return window.inspected ? backend.value(window.inspectedModule, window.inspected.id) : "—";
                    }
                    font.pixelSize: 20
                    color: design.text
                }
                Label {
                    text: window.inspected ? "По умолчанию: " + window.inspected.default : ""
                    font.pixelSize: design.smallSize
                    color: design.secondary
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        // One toolbar, separate from content. Linux/Qt owns the native window decoration.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 62
            color: design.toolbar
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 20
                spacing: 12
                PreviewButton {
                    tokens: design
                    symbol: "sidebar"
                    quiet: true
                    Accessible.name: "Показать или скрыть боковую панель"
                    onClicked: window.sidebarShown = !window.sidebarShown
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: window.titleFor(window.section)
                        font.weight: Font.DemiBold
                        font.pixelSize: design.bodySize
                        color: design.text
                    }
                    Label {
                        text: {
                            backend.schema;
                            backend.revision;
                            return window.choiceText("game") + " · " + window.choiceText("port");
                        }
                        font.pixelSize: design.smallSize
                        color: design.secondary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                RowLayout {
                    visible: window.section === "resources" && !window.query
                    spacing: 2
                    PreviewButton {
                        tokens: design
                        symbol: "grid"
                        quiet: true
                        selected: window.resourceViewMode === "grid"
                        Accessible.name: "Показать значками · Ctrl+1"
                        onClicked: window.resourceViewMode = "grid"
                    }
                    PreviewButton {
                        tokens: design
                        symbol: "list"
                        quiet: true
                        selected: window.resourceViewMode === "list"
                        Accessible.name: "Показать списком · Ctrl+2"
                        onClicked: window.resourceViewMode = "list"
                    }
                }
                PreviewButton {
                    tokens: design
                    symbol: backend.dark ? "appearance" : "moon"
                    quiet: true
                    Accessible.name: "Сменить светлую и тёмную тему"
                    onClicked: backend.dark = !backend.dark
                }
                PreviewButton {
                    tokens: design
                    symbol: "inspector"
                    quiet: true
                    Accessible.name: "Показать или скрыть инспектор"
                    onClicked: {
                        if (window.width < 1200)
                            inspectorDialog.open();
                        else
                            window.inspectorShown = !window.inspectorShown;
                    }
                }
                PreviewButton {
                    tokens: design
                    symbol: "project"
                    quiet: true
                    Accessible.name: "Меню команд"
                    onClicked: commands.popup()
                }
                Rectangle {
                    implicitWidth: 1
                    implicitHeight: 22
                    color: design.line
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                }
                PreviewButton {
                    tokens: design
                    text: "Отмена"
                    visible: backend.busy
                    onClicked: backend.cancel()
                }
                PreviewButton {
                    id: createButton
                    tokens: design
                    text: "Создать карту"
                    primary: true
                    enabled: !backend.busy && !backend.loading && !!backend.schema.protocol
                    onClicked: window.generate()
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: design.line
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            Rectangle {
                id: sidebarPanel
                property real reveal: window.sidebarShown ? 1 : 0
                Behavior on reveal {
                    NumberAnimation {
                        id: sidebarMotion
                        duration: design.panelDuration
                        easing.type: Easing.OutCubic
                    }
                }
                visible: reveal > 0.001
                clip: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: 210 * reveal
                Layout.preferredWidth: 210 * reveal
                Layout.fillHeight: true
                color: design.sidebar
                ColumnLayout {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 16
                    width: 178
                    opacity: sidebarPanel.reveal
                    spacing: 8
                    Label {
                        text: "Obsidian"
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                        color: design.text
                        Layout.topMargin: 14
                    }
                    Label {
                        text: "Конструктор уровней"
                        font.pixelSize: design.smallSize
                        color: design.secondary
                        Layout.bottomMargin: 24
                    }
                    Label {
                        text: "Карта"
                        font.pixelSize: design.smallSize
                        font.weight: Font.DemiBold
                        color: design.secondary
                        leftPadding: 8
                    }
                    ScrollView {
                        id: sidebarScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 0
                        contentWidth: availableWidth
                        clip: true
                        ColumnLayout {
                            width: sidebarScroll.availableWidth
                            spacing: 4
                            Repeater {
                                model: window.categories
                                ItemDelegate {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(36, design.bodySize + 20)
                                    Accessible.name: modelData.title
                                    onClicked: window.go(modelData.key)
                                    contentItem: RowLayout {
                                        spacing: 10
                                        PreviewIcon {
                                            name: modelData.icon
                                            ink: ({
                                                    project: "#77818d",
                                                    geometry: "#1686e8",
                                                    combat: "#ed625f",
                                                    resources: "#e89925",
                                                    appearance: "#a778d8",
                                                    results: "#1b9ec9"
                                                })[modelData.key]
                                        }
                                        Label {
                                            text: modelData.title
                                            font.pixelSize: design.bodySize
                                            color: window.section === modelData.key ? design.selectionText : design.text
                                            Layout.fillWidth: true
                                        }
                                    }
                                    background: Rectangle {
                                        radius: 6
                                        color: window.section === modelData.key ? design.selection : parent.hovered ? design.hover : "transparent"
                                        border.width: parent.visualFocus ? 2 : 0
                                        border.color: design.accent
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: design.reduceMotion ? 0 : 130
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    PreviewButton {
                        tokens: design
                        text: "Игра и формат…"
                        Layout.fillWidth: true
                        enabled: !backend.busy && !backend.loading
                        onClicked: gameDialog.open()
                    }
                    Label {
                        text: "Образец дизайна"
                        font.pixelSize: design.smallSize
                        color: design.secondary
                        Layout.topMargin: 12
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    height: parent.height
                    width: 1
                    color: design.line
                }
            }
            ScrollView {
                id: contentScroll
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: availableWidth
                clip: true
                ScrollBar.vertical.active: true
                ColumnLayout {
                    id: pageContent
                    transform: Translate {
                        id: pageShift
                    }
                    width: contentScroll.availableWidth
                    spacing: 24
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: 28
                        Layout.bottomMargin: 0
                        spacing: 8
                        Label {
                            text: window.query ? "Результаты поиска" : window.titleFor(window.section)
                            font.pixelSize: Math.round(28 * design.textScale)
                            font.weight: Font.DemiBold
                            color: design.text
                        }
                        Label {
                            text: window.section === "resources" ? "Выберите категорию, чтобы настроить предметы на карте." : window.section === "combat" ? "Задайте ритм и сложность столкновений." : window.section === "results" ? "Созданная карта и файлы результата." : "Настройте основные свойства будущей карты."
                            font.pixelSize: design.bodySize
                            color: design.secondary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                    RowLayout {
                        visible: window.section !== "results"
                        Layout.fillWidth: true
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        spacing: 12
                        TextField {
                            id: search
                            Layout.fillWidth: true
                            implicitHeight: 34
                            placeholderText: "Поиск параметров"
                            text: window.query
                            selectByMouse: true
                            Accessible.name: "Поиск параметров"
                            onTextEdited: {
                                window.query = text;
                                Qt.callLater(function () {
                                    search.forceActiveFocus();
                                });
                            }
                            background: Rectangle {
                                radius: 7
                                color: design.surface
                                border.color: parent.activeFocus ? design.accent : design.line
                                border.width: parent.activeFocus ? 2 : 1
                            }
                        }
                        CheckBox {
                            text: "Расширенные"
                            checked: window.advanced
                            font.pixelSize: design.smallSize
                            onToggled: window.advanced = checked
                        }
                    }
                    Rectangle {
                        visible: window.section === "project" && !window.query
                        Layout.fillWidth: true
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        implicitHeight: projectSetup.implicitHeight + 32
                        color: design.surface
                        radius: 10
                        border.color: design.line
                        GameSetup {
                            id: projectSetup
                            anchors.fill: parent
                            anchors.margins: 16
                        }
                    }
                    ResourceGallery {
                        id: resourceGallery
                        tokens: design
                        entries: window.resourceEntries()
                        visible: window.section === "resources" && !window.query
                        selectedId: window.currentResourceId
                        viewMode: window.resourceViewMode
                        compatible: window.resourceGameCompatible
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        onSelect: function (id, openPanel) {
                            window.selectResource(id, openPanel);
                        }
                        onRevealItem: function (item) {
                            let flick = contentScroll.contentItem;
                            let top = item.mapToItem(flick.contentItem, 0, 0).y;
                            let bottom = top + item.height;
                            let target = flick.contentY;
                            if (top < target)
                                target = top - 12;
                            else if (bottom > target + flick.height)
                                target = bottom - flick.height + 12;
                            flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), target));
                        }
                    }
                    Repeater {
                        model: window.section === "results" ? [] : window.modules()
                        ColumnLayout {
                            id: group
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.leftMargin: 28
                            Layout.rightMargin: 28
                            spacing: 10
                            Label {
                                text: group.modelData.title
                                font.pixelSize: design.smallSize
                                font.weight: Font.DemiBold
                                color: design.secondary
                                leftPadding: 2
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: groupRows.implicitHeight + 8
                                color: design.surface
                                radius: 10
                                border.color: design.line
                                ColumnLayout {
                                    id: groupRows
                                    width: parent.width
                                    spacing: 0
                                    y: 4
                                    Repeater {
                                        model: group.modelData.options
                                        PreviewOptionRow {
                                            required property var modelData
                                            tokens: design
                                            option: modelData
                                            moduleId: group.modelData.id
                                            enabled: !backend.busy && !backend.loading
                                            onInspect: function (openPanel) {
                                                window.inspect(modelData, group.modelData.id, openPanel);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Label {
                        visible: window.section !== "results" && window.modules().length === 0 && window.section !== "project"
                        text: backend.loading ? "Загрузка настроек…" : "Ничего не найдено. Попробуйте другой запрос."
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        color: design.secondary
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        visible: window.section !== "results"
                        color: design.surface
                        radius: 10
                        border.color: design.line
                        implicitHeight: seedGroup.implicitHeight + 32
                        ColumnLayout {
                            id: seedGroup
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12
                            RowLayout {
                                Layout.fillWidth: true
                                Label {
                                    text: "Seed"
                                    font.pixelSize: design.bodySize
                                    color: design.text
                                    Layout.fillWidth: true
                                }
                                TextField {
                                    Layout.preferredWidth: 180
                                    text: {
                                        backend.revision;
                                        return backend.value("", "seed");
                                    }
                                    placeholderText: "0 — случайный"
                                    selectByMouse: true
                                    enabled: !backend.busy && !backend.loading
                                    Accessible.name: "Seed генерации"
                                    onEditingFinished: backend.setGeneral("seed", text)
                                }
                            }
                            Label {
                                text: "Оставьте 0 для нового случайного seed при создании карты."
                                color: design.secondary
                                font.pixelSize: design.smallSize
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                    ColumnLayout {
                        visible: window.section === "results"
                        Layout.fillWidth: true
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        spacing: 16
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 340
                            color: design.surface
                            radius: 10
                            border.color: design.line
                            WadView {
                                anchors.fill: parent
                                anchors.margins: 8
                                file: backend.previewFile
                            }
                        }
                        Label {
                            text: backend.resultFolder || "Создайте первую карту — здесь появится результат."
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                            color: design.secondary
                            font.pixelSize: design.bodySize
                        }
                        PreviewButton {
                            tokens: design
                            text: "Открыть папку результата"
                            enabled: !!backend.resultFolder
                            onClicked: backend.openResult()
                        }
                        Label {
                            text: "Журнал генерации"
                            font.weight: Font.DemiBold
                            color: design.text
                        }
                        TextArea {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 220
                            text: backend.log
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            font.pixelSize: design.smallSize
                        }
                    }
                    Label {
                        visible: window.section !== "results"
                        text: "F2 — создать карту  ·  Ctrl+G — игра и формат"
                        color: design.secondary
                        font.pixelSize: design.smallSize
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                    Item {
                        implicitHeight: 24
                    }
                }
            }
            Rectangle {
                id: inspectorPanel
                property real reveal: window.inlineInspector ? 1 : 0
                Behavior on reveal {
                    NumberAnimation {
                        id: inspectorMotion
                        duration: design.panelDuration
                        easing.type: Easing.OutCubic
                    }
                }
                visible: reveal > 0.001
                clip: true
                Layout.minimumWidth: 0
                Layout.maximumWidth: 310 * reveal
                Layout.preferredWidth: 310 * reveal
                Layout.fillHeight: true
                color: design.surface
                Rectangle {
                    width: 1
                    height: parent.height
                    color: design.line
                }
                Loader {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 20
                    width: 270
                    opacity: inspectorPanel.reveal
                    sourceComponent: inspectorContent
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 34
            color: design.canvas
            Rectangle {
                width: parent.width
                height: 1
                color: design.line
            }
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 10
                BusyIndicator {
                    visible: backend.busy || backend.loading
                    running: visible
                    implicitWidth: 18
                    implicitHeight: 18
                }
                Label {
                    text: backend.status
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    font.pixelSize: design.smallSize
                    color: design.secondary
                }
                Label {
                    visible: window.width > 1050
                    text: backend.outputFolder
                    Layout.maximumWidth: 350
                    elide: Text.ElideMiddle
                    font.pixelSize: design.smallSize
                    color: design.secondary
                }
                ToolButton {
                    text: "Папка…"
                    enabled: !backend.busy
                    onClicked: outputDialog.open()
                    font.pixelSize: design.smallSize
                }
            }
        }
    }
}
