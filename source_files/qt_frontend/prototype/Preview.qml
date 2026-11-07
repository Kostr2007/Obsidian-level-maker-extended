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
    font: design.bodyFont
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
    // Session-only experiment: classic remains the default on every launch.
    property string resourceSelectionStyle: "classic"
    // ART-02 is session-local; the retained zebra remains the launch default.
    property string geometryTextureStyle: "zebra"
    // ART-03 is limited to the selected Ammo inspector and never persisted.
    property string ammoInspectorStyle: "original"
    // ART-04 B is accepted; the original icons remain available for comparison.
    property string sidebarIconStyle: "badges"
    // ART-05 affects only the level-size numeric handle and is never persisted.
    property string levelSizeSliderStyle: "capsule"
    readonly property bool priorityAmmoInspector: ammoInspectorStyle === "priority" && section === "resources" && inspectedModule === "ui_pickups" && inspected && inspected.id === "ammo" && resourceGameCompatible
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
    readonly property bool inlineInspector: width >= 1200 && inspectorShown && section !== "results"
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
                    if (o.category === section && o.kind !== "header" && (advanced || !o.advanced)) {
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
        enabled: window.section !== "results"
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
        sequence: "Ctrl+Shift+P"
        onActivated: commands.popup(commandsButton, 0, commandsButton.height + 6)
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
    ButtonGroup {
        id: resourceSelectionGroup
    }
    ButtonGroup {
        id: ammoInspectorGroup
    }
    ButtonGroup {
        id: geometryTextureGroup
    }
    ButtonGroup {
        id: sidebarIconGroup
    }
    ButtonGroup {
        id: levelSizeSliderGroup
    }
    PreviewMenu {
        id: commands
        tokens: design
        PreviewMenuItem {
            tokens: design
            text: "Создать карту  ·  F2"
            enabled: createButton.enabled
            onTriggered: window.generate()
        }
        PreviewMenuItem {
            tokens: design
            text: "Игра и формат…  ·  Ctrl+G"
            enabled: !backend.loading && !backend.busy
            onTriggered: gameDialog.open()
        }
        MenuSeparator {
            padding: 6
            contentItem: Rectangle {
                implicitWidth: 200
                implicitHeight: 1
                color: design.line
            }
        }
        PreviewMenuItem {
            tokens: design
            text: "Импорт пресета…"
            enabled: !backend.loading && !backend.busy
            onTriggered: loadConfig.open()
        }
        PreviewMenuItem {
            tokens: design
            text: "Сохранить пресет…"
            enabled: !backend.loading && !backend.busy
            onTriggered: saveConfig.open()
        }
        PreviewMenuItem {
            tokens: design
            text: "Папка результатов…"
            enabled: !backend.busy
            onTriggered: outputDialog.open()
        }
        MenuSeparator {
            padding: 6
            contentItem: Rectangle {
                implicitWidth: 200
                implicitHeight: 1
                color: design.line
            }
        }
        PreviewMenuItem {
            tokens: design
            text: "Боковая панель  ·  Ctrl+Shift+B"
            checkable: true
            checked: window.sidebarShown
            onTriggered: window.sidebarShown = checked
        }
        PreviewMenuItem {
            tokens: design
            text: "Инспектор  ·  Ctrl+I"
            enabled: window.section !== "results"
            onTriggered: {
                if (window.width < 1200)
                    inspectorDialog.open();
                else
                    window.inspectorShown = !window.inspectorShown;
            }
        }
        PreviewMenuItem {
            tokens: design
            objectName: "resourceStyleClassic"
            ButtonGroup.group: resourceSelectionGroup
            text: "Ресурсы: A · Классическое выделение"
            checkable: true
            checked: window.resourceSelectionStyle === "classic"
            onTriggered: window.resourceSelectionStyle = "classic"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "resourceStyleArt01"
            ButtonGroup.group: resourceSelectionGroup
            text: "Ресурсы: B · ART-01 (эксперимент)"
            checkable: true
            checked: window.resourceSelectionStyle === "art01"
            onTriggered: window.resourceSelectionStyle = "art01"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "geometryTextureZebra"
            ButtonGroup.group: geometryTextureGroup
            text: "Структура: A · Полосы"
            checkable: true
            checked: window.geometryTextureStyle === "zebra"
            onTriggered: window.geometryTextureStyle = "zebra"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "geometryTextureUniform"
            ButtonGroup.group: geometryTextureGroup
            text: "Структура: B · ART-02 (эксперимент)"
            checkable: true
            checked: window.geometryTextureStyle === "uniform"
            onTriggered: window.geometryTextureStyle = "uniform"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "ammoInspectorOriginal"
            ButtonGroup.group: ammoInspectorGroup
            text: "Инспектор боеприпасов: A · Исходный"
            checkable: true
            checked: window.ammoInspectorStyle === "original"
            onTriggered: window.ammoInspectorStyle = "original"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "ammoInspectorPriority"
            ButtonGroup.group: ammoInspectorGroup
            text: "Инспектор боеприпасов: B · ART-03 (эксперимент)"
            checkable: true
            checked: window.ammoInspectorStyle === "priority"
            onTriggered: window.ammoInspectorStyle = "priority"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "sidebarIconsOriginal"
            ButtonGroup.group: sidebarIconGroup
            text: "Значки: A · Исходные"
            checkable: true
            checked: window.sidebarIconStyle === "original"
            onTriggered: window.sidebarIconStyle = "original"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "sidebarIconsBadges"
            ButtonGroup.group: sidebarIconGroup
            text: "Значки: B · ART-04 (эксперимент)"
            checkable: true
            checked: window.sidebarIconStyle === "badges"
            onTriggered: window.sidebarIconStyle = "badges"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "levelSizeSliderOriginal"
            ButtonGroup.group: levelSizeSliderGroup
            text: "Бегунок: A · Исходный"
            checkable: true
            checked: window.levelSizeSliderStyle === "original"
            onTriggered: window.levelSizeSliderStyle = "original"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "levelSizeSliderDisc"
            ButtonGroup.group: levelSizeSliderGroup
            text: "Бегунок: B · Светлый диск"
            checkable: true
            checked: window.levelSizeSliderStyle === "disc"
            onTriggered: window.levelSizeSliderStyle = "disc"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "levelSizeSliderCapsule"
            ButtonGroup.group: levelSizeSliderGroup
            text: "Бегунок: C · Капсула"
            checkable: true
            checked: window.levelSizeSliderStyle === "capsule"
            onTriggered: window.levelSizeSliderStyle = "capsule"
        }
        PreviewMenuItem {
            tokens: design
            objectName: "levelSizeSliderTile"
            ButtonGroup.group: levelSizeSliderGroup
            text: "Бегунок: D · Акцентная плитка"
            checkable: true
            checked: window.levelSizeSliderStyle === "tile"
            onTriggered: window.levelSizeSliderStyle = "tile"
        }
        PreviewMenuItem {
            tokens: design
            text: "Тёмное оформление"
            checkable: true
            checked: backend.dark
            onTriggered: backend.dark = checked
        }
        PreviewMenuItem {
            tokens: design
            text: "Увеличенный текст"
            checkable: true
            checked: design.textScale > 1
            onTriggered: design.textScale = checked ? 1.25 : 1
        }
        PreviewMenuItem {
            tokens: design
            text: "Меньше анимации  ·  Ctrl+Shift+M"
            checkable: true
            checked: design.reduceMotion
            onTriggered: design.reduceMotion = checked
        }
        MenuSeparator {
            padding: 6
            contentItem: Rectangle {
                implicitWidth: 200
                implicitHeight: 1
                color: design.line
            }
        }
        PreviewMenuItem {
            tokens: design
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
    PreviewDialog {
        id: gameDialog
        tokens: design
        objectName: "gameDialog"
        title: "Игра и формат"
        anchors.centerIn: Overlay.overlay
        modal: true
        width: Math.min(680, window.width - 48)
        height: Math.min(window.height - 48, gameDialogSetup.implicitHeight + gameDialog.chromeHeight)
        standardButtons: Dialog.Ok
        contentItem: ScrollView {
            id: gameScroll
            contentWidth: availableWidth
            GameSetup {
                id: gameDialogSetup
                tokens: design
                width: gameScroll.availableWidth
            }
        }
    }
    PreviewDialog {
        id: exitDialog
        tokens: design
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
    PreviewDialog {
        id: inspectorDialog
        tokens: design
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
            objectName: "inspectorScroll"
            rightPadding: 12
            contentWidth: availableWidth
            clip: true
            ScrollBar.vertical.active: true
            GridLayout {
                columns: 1
                columnSpacing: 0
                width: helpScroll.availableWidth
                rowSpacing: 16
                Label {
                    Layout.row: 0
                    text: !window.inspected && window.section === "project" ? "О проекте" : "Об этом параметре"
                    font: design.captionFont
                    color: design.secondary
                }
                Label {
                    Layout.row: 1
                    objectName: "resourceDetailTitle"
                    text: window.inspected ? window.inspected.title : window.section === "project" ? "Игра и совместимость" : "Выберите параметр"
                    font: design.detailFont
                    color: design.text
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                Label {
                    objectName: "inspectorDescription"
                    Layout.row: 2
                    text: window.inspected ? (window.inspected.summary || window.inspected.tooltip) : window.section === "project" ? "Движок, игра и порт определяют доступные возможности генератора. После изменения дождитесь обновления параметров." : "Нажмите кнопку информации рядом с названием."
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: design.secondary
                    font: design.bodyFont
                    lineHeight: 1.15
                }
                AssetPreview {
                    objectName: "inspectorAssets"
                    unifiedSurface: window.priorityAmmoInspector
                    Layout.row: window.priorityAmmoInspector ? 6 : 3
                    tokens: design
                    textScale: design.textScale
                    optionId: window.inspectedModule === "ui_pickups" && window.inspected ? window.inspected.id : ""
                    visible: available
                }
                GameplayComparison {
                    Layout.row: window.priorityAmmoInspector ? 7 : 4
                    tokens: design
                    example: window.inspected ? window.inspected.comparison : ""
                    visible: supported
                }
                Label {
                    Layout.row: window.priorityAmmoInspector ? 8 : 5
                    text: window.inspected ? window.inspected.related : ""
                    visible: !!text
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: design.secondary
                    font: design.captionFont
                }
                Rectangle {
                    Layout.row: window.priorityAmmoInspector ? 3 : 6
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: design.line
                }
                Label {
                    Layout.row: window.priorityAmmoInspector ? 4 : 7
                    visible: !!window.inspected
                    objectName: "inspectorValueTitle"
                    text: "Текущее значение"
                    font: design.captionFont
                    color: design.secondary
                }
                Label {
                    Layout.row: window.priorityAmmoInspector ? 5 : 8
                    visible: !!window.inspected
                    objectName: "inspectorValue"
                    text: {
                        backend.revision;
                        return window.inspected ? backend.value(window.inspectedModule, window.inspected.id) : "—";
                    }
                    font: design.sectionFont
                    color: design.text
                }
                Label {
                    Layout.row: 9
                    visible: !!window.inspected
                    objectName: "inspectorDefault"
                    text: window.inspected ? "По умолчанию: " + window.inspected.default : ""
                    font: design.captionFont
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
                        font: design.sectionFont
                        color: design.text
                    }
                    Label {
                        text: {
                            backend.schema;
                            backend.revision;
                            return window.choiceText("game") + " · " + window.choiceText("port");
                        }
                        font: design.captionFont
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
                    visible: window.section !== "results"
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
                    id: commandsButton
                    tokens: design
                    objectName: "commandsButton"
                    symbol: "project"
                    quiet: true
                    tooltipEnabled: !commands.visible
                    Accessible.name: "Меню команд"
                    onClicked: commands.popup(commandsButton, 0, commandsButton.height + 6)
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
                objectName: "sidebarPanel"
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
                        font: design.brandFont
                        color: design.text
                        Layout.topMargin: 14
                    }
                    Label {
                        text: "Конструктор уровней"
                        font: design.captionFont
                        color: design.secondary
                        Layout.bottomMargin: 24
                    }
                    Label {
                        text: "Карта"
                        font: design.sectionFont
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
                                    objectName: "sidebarRow_" + modelData.key
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(36, design.bodySize + 20)
                                    Accessible.name: modelData.title
                                    onClicked: window.go(modelData.key)
                                    contentItem: RowLayout {
                                        spacing: 10
                                        Item {
                                            objectName: "sidebarIconSlot_" + modelData.key
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            readonly property color originalInk: ({
                                                    project: "#77818d",
                                                    geometry: "#1686e8",
                                                    combat: "#ed625f",
                                                    resources: "#e89925",
                                                    appearance: "#a778d8",
                                                    results: "#1b9ec9"
                                                })[modelData.key]
                                            Rectangle {
                                                objectName: "sidebarIconBadge_" + modelData.key
                                                anchors.centerIn: parent
                                                width: 22
                                                height: 22
                                                radius: 5
                                                visible: window.sidebarIconStyle === "badges"
                                                color: ({
                                                        project: "#77818d",
                                                        geometry: "#1678ce",
                                                        combat: "#d44946",
                                                        resources: "#b87512",
                                                        appearance: "#9864c8",
                                                        results: "#147fa3"
                                                    })[modelData.key]
                                            }
                                            PreviewIcon {
                                                objectName: "sidebarIconGlyph_" + modelData.key
                                                anchors.fill: parent
                                                name: modelData.icon
                                                ink: window.sidebarIconStyle === "badges" ? "#ffffff" : parent.originalInk
                                            }
                                        }
                                        Label {
                                            objectName: "sidebarLabel_" + modelData.key
                                            text: modelData.title
                                            font: design.navigationFont
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
                        font: design.captionFont
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
                            objectName: "pageTitle"
                            font: design.titleFont
                            color: design.text
                        }
                        Label {
                            text: window.section === "resources" ? "Выберите категорию, чтобы настроить предметы на карте." : window.section === "combat" ? "Задайте ритм и сложность столкновений." : window.section === "results" ? "Созданная карта и файлы результата." : "Настройте основные свойства будущей карты."
                            font: design.bodyFont
                            color: design.secondary
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }
                    Rectangle {
                        visible: window.section !== "results"
                        Layout.fillWidth: true
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        implicitHeight: searchTools.implicitHeight + 16
                        radius: 8
                        color: design.toolbar
                        RowLayout {
                            id: searchTools
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12
                            PreviewTextField {
                                id: search
                                tokens: design
                                Layout.fillWidth: true
                                Layout.preferredWidth: 360
                                Layout.maximumWidth: 480
                                Layout.minimumWidth: 100
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
                            }
                            CheckBox {
                                id: advancedToggle
                                text: "Расширенные"
                                indicator: Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    x: advancedToggle.leftPadding
                                    y: (advancedToggle.height - height) / 2
                                    radius: 4
                                    color: advancedToggle.checked ? design.accent : design.surface
                                    border.color: advancedToggle.visualFocus ? design.accent : design.line
                                    border.width: advancedToggle.visualFocus ? 2 : 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        visible: advancedToggle.checked
                                        font: design.captionFont
                                        color: design.accentText
                                    }
                                }
                                contentItem: Text {
                                    text: advancedToggle.text
                                    font: design.bodyFont
                                    color: design.text
                                    leftPadding: advancedToggle.indicator.width + 8
                                    verticalAlignment: Text.AlignVCenter
                                }
                                checked: window.advanced
                                font: design.bodyFont
                                onToggled: window.advanced = checked
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                            }
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
                            tokens: design
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
                        selectionStyle: window.resourceSelectionStyle
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
                    Column {
                        id: formGroups
                        // Keep recreated search delegates outside pageContent's layout cache (Qt 6.4).
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        spacing: 24
                        Repeater {
                            model: window.section === "results" ? [] : window.modules()
                            ColumnLayout {
                                id: group
                                required property var modelData
                                width: formGroups.width
                                spacing: 10
                                Label {
                                    objectName: "groupTitle_" + group.modelData.id
                                    text: group.modelData.title
                                    font: design.sectionFont
                                    color: design.text
                                    leftPadding: 2
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: groupRows.implicitHeight + 8
                                    color: design.surface
                                    radius: 10
                                    border.color: design.line
                                    Column {
                                        id: groupRows
                                        width: parent.width
                                        spacing: 0
                                        y: 4
                                        Repeater {
                                            model: group.modelData.options
                                            PreviewOptionRow {
                                                width: groupRows.width
                                                required property var modelData
                                                required property int index
                                                stripeIndex: index
                                                uniformSurface: window.section === "geometry" && group.modelData.id === "ui_arch" && window.geometryTextureStyle === "uniform"
                                                separatorAfter: uniformSurface && index < group.modelData.options.length - 1
                                                tokens: design
                                                sliderStyle: moduleId === "ui_arch" && option.id === "float_size" ? window.levelSizeSliderStyle : "original"
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
                    ColumnLayout {
                        visible: window.section !== "results"
                        Layout.fillWidth: true
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        spacing: 10
                        Label {
                            text: "Генерация"
                            font: design.sectionFont
                            color: design.text
                            leftPadding: 2
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: seedGroup.implicitHeight + 16
                            radius: 10
                            color: design.surface
                            border.color: design.line
                            ColumnLayout {
                                id: seedGroup
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 6
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    Label {
                                        text: "Seed"
                                        font: design.bodyFont
                                        color: design.text
                                        Layout.fillWidth: true
                                    }
                                    PreviewTextField {
                                        tokens: design
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
                                    text: "0 — новый случайный seed при создании карты."
                                    color: design.secondary
                                    font: design.captionFont
                                    Layout.leftMargin: 8
                                    Layout.rightMargin: 8
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        visible: window.section === "results"
                        Layout.fillWidth: true
                        Layout.leftMargin: 28
                        Layout.rightMargin: 28
                        spacing: 14
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: mapCard.implicitHeight + 24
                            color: design.surface
                            radius: 12
                            border.color: design.line
                            ColumnLayout {
                                id: mapCard
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Label {
                                        text: resultMap.mapName || "План уровня"
                                        font: design.sectionFont
                                        color: design.text
                                        Layout.fillWidth: true
                                    }
                                    PreviewButton {
                                        tokens: design
                                        text: "−"
                                        Accessible.name: "Уменьшить карту"
                                        enabled: resultMap.lineCount > 0
                                        onClicked: resultMap.zoom /= 1.25
                                    }
                                    Label {
                                        text: Math.round(resultMap.zoom * 100) + "%"
                                        font: design.captionFont
                                        color: design.secondary
                                        Layout.preferredWidth: 48
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    PreviewButton {
                                        tokens: design
                                        text: "+"
                                        Accessible.name: "Увеличить карту"
                                        enabled: resultMap.lineCount > 0
                                        onClicked: resultMap.zoom *= 1.25
                                    }
                                    PreviewButton {
                                        tokens: design
                                        text: "Вписать"
                                        enabled: resultMap.lineCount > 0
                                        onClicked: resultMap.resetView()
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Math.max(260, Math.min(520, window.height * .54))
                                    clip: true
                                    WadView {
                                        id: resultMap
                                        objectName: "resultMap"
                                        anchors.fill: parent
                                        file: backend.previewFile
                                        showAll: false
                                        canvasColor: design.canvas
                                        wallColor: design.dark ? "#a0c6f5" : "#386b9f"
                                        detailColor: design.dark ? "#65738a" : "#a0aab8"
                                        gridColor: design.dark ? "#29292f" : "#eff1f5"
                                        viewFont: design.bodyFont
                                        Accessible.name: "План созданного уровня"
                                        Accessible.description: "Колесо — масштаб, перетаскивание — перемещение, Home — вписать, плюс и минус — масштаб"
                                    }
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "transparent"
                                        border.color: resultMap.activeFocus ? design.accent : "transparent"
                                        radius: 5
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    PreviewButton {
                                        tokens: design
                                        text: resultMap.showAll ? "Вся геометрия" : "Основная область"
                                        enabled: resultMap.lineCount > 0
                                        Accessible.description: "Переключить вписывание основной связной области и всей геометрии, включая служебные участки"
                                        onClicked: resultMap.showAll = !resultMap.showAll
                                    }
                                    Label {
                                        text: "Колесо — масштаб · Перетаскивание — перемещение"
                                        font: design.captionFont
                                        color: design.secondary
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                    Label {
                                        text: resultMap.lineCount ? (resultMap.showAll ? resultMap.lineCount : resultMap.mainLineCount) + " линий" : ""
                                        font: design.captionFont
                                        color: design.secondary
                                    }
                                }
                            }
                        }
                        Label {
                            text: backend.resultFolder || "Создайте первую карту — здесь появится результат."
                            Layout.fillWidth: true
                            wrapMode: Text.WrapAnywhere
                            color: design.secondary
                            font: design.captionFont
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            PreviewButton {
                                tokens: design
                                text: "Открыть папку результата"
                                enabled: !!backend.resultFolder
                                onClicked: backend.openResult()
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            PreviewButton {
                                id: logToggle
                                tokens: design
                                text: checked ? "Скрыть журнал" : "Журнал генерации"
                                checkable: true
                            }
                        }
                        TextArea {
                            visible: logToggle.checked
                            Layout.fillWidth: true
                            Layout.preferredHeight: 220
                            text: backend.log
                            readOnly: true
                            selectByMouse: true
                            wrapMode: TextEdit.Wrap
                            font: design.monoFont
                            color: design.text
                            background: Rectangle {
                                color: design.surface
                                radius: 8
                                border.color: design.line
                            }
                        }
                    }
                    Label {
                        visible: window.section !== "results"
                        text: "F2 — создать карту  ·  Ctrl+G — игра и формат"
                        color: design.secondary
                        font: design.captionFont
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
                    font: design.captionFont
                    color: design.secondary
                }
                Label {
                    visible: window.width > 1050
                    text: backend.outputFolder
                    Layout.maximumWidth: 350
                    elide: Text.ElideMiddle
                    font: design.captionFont
                    color: design.secondary
                }
                PreviewButton {
                    tokens: design
                    quiet: true
                    text: "Папка…"
                    enabled: !backend.busy
                    onClicked: outputDialog.open()
                    font: design.captionFont
                }
            }
        }
    }
}
