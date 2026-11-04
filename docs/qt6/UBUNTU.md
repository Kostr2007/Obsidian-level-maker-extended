# Qt 6: установка и запуск в Ubuntu

Основной интерфейс Obsidian Extended теперь написан на **Qt 6 / Qt Quick Controls 2**.
Генератор C++/Lua сохранён отдельным `obsidian-engine`: Qt не зависит от FLTK.

## Готовая сборка

Архив Ubuntu 24.04 x86_64 рассчитан на Ubuntu 24.04 и новее той же архитектуры.
Скачайте его в [GitHub Releases](https://github.com/Kostr2007/Obsidian-level-maker-extended/releases)
или используйте архив, предоставленный вместе с изменениями.

Установите библиотеки Qt и QML-модули:

```sh
sudo apt update
sudo apt install qml6-module-qtquick qml6-module-qtquick-controls qml6-module-qtquick-layouts qml6-module-qtquick-dialogs qml6-module-qtquick-templates qml6-module-qtquick-window qml6-module-qtqml-workerscript qml6-module-qtqml-models qt6-qpa-plugins qt6-wayland
```

```sh
tar -xzf Obsidian-Extended-0.3.0-qt6-ubuntu-24.04-x86_64.tar.gz
cd Obsidian-Extended
./start.sh
```

Имя архива локальной упаковки — `Obsidian-Extended-Qt6-linux-x86_64.tar.gz`.
Не переносите один исполняемый файл: нужны оба бинарника и каталоги ресурсов.
Непосредственная установка в системные каталоги не требуется.

## Сборка из исходников

```sh
sudo apt install build-essential cmake ninja-build flex qt6-base-dev qt6-declarative-dev
./scripts/dev/build-linux.sh
./obsidian
```

Понадобятся также QML-модули из команды выше. Минимальная версия Qt — 6.4.
Для упаковки выполните `./scripts/dev/package-linux.sh`.

## Как пользоваться

1. Выберите игру, порт, длину и тему мира. Списки берутся из движка с учётом
   совместимости, включая подключённые дополнения.
2. В разделах «Мир», «Бой и предметы», «Модули» настройте параметры. Карточки
   сворачиваются; слайдеры допускают точный ввод и возврат к значению по умолчанию.
3. Укажите seed или оставьте 0 для случайного. Кнопка ↻ возвращает случайный режим.
Seed передаётся движку без изменения, но у старого генератора обнаружены случаи
недетерминизма с полной конфигурацией: [подробности](ENGINE_NOTES.md).

4. Выберите папку результатов и нажмите «Создать карту» или F2.
5. Завершённая сборка появляется в отдельной подпапке `Obsidian-*`: карта,
   конфигурация и журнал. Для Doom/Hexen WAD отображается настоящая геометрия
   первой карты, в том числе UDMF. PK3 и другие форматы открываются через папку.

«Отмена» удаляет только временную незавершённую сборку. Старые результаты не
перезаписываются. При ошибке подробности доступны в «Журнале». Наличие
геометрического предпросмотра не является проверкой проходимости карты.

Пресеты можно импортировать из старых `CONFIG.txt` и экспортировать обратно.
Неизвестные параметры сохраняются. Настройки Qt и автосохранённая конфигурация
лежат в пользовательском каталоге `QStandardPaths::AppConfigLocation`
(обычно `~/.config/ObsidianExtended/ObsidianExtended`); оригинальный импортируемый
файл не меняется. Старый `THEME.txt` относится к FLTK и не используется Qt.

При небольшой высоте окна параметры игры открываются кнопкой «Выбрать игру»
в отдельном диалоге; основное действие остаётся на экране.

Клавиатура: Ctrl+F — поиск, Ctrl+G — параметры игры, F2 — генерация,
Alt+1…6 — разделы, Ctrl+Q — выход.
Подключение внешних дополнений и светлая/тёмная схема доступны в «Настройках».
Названия параметров движка пока используют существующие английские переводы;
основные элементы нового интерфейса — на русском.

## Диагностика

Если драйвер графики не поддерживает нужный режим Qt Quick:

```sh
QT_QUICK_BACKEND=software ./start.sh
```

Переход на XWayland при проблеме нативного Wayland:

```sh
QT_QPA_PLATFORM=xcb ./start.sh
```

X11/Xvfb и программный renderer проверяются автоматически; нативный Wayland
на каждом настольном окружении отдельно не проверен.

Для разработчиков:

```sh
ctest --test-dir build/qt --output-on-failure --no-tests=error -R '^qt-core$'
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software ./obsidian --smoke-output "$PWD/build/qt-smoke"
# Дополнительно: sudo apt install xvfb xdotool imagemagick
python3 scripts/dev/check-qt.py
```

CLI генератора доступен через `obsidian-engine`; прежний `./obsidian --batch ...`
передаётся worker без запуска окна. Для старого FLTK-интерфейса остаётся явная
сборка `-DOBSIDIAN_QT=OFF`; его оформление больше не является основным UI.
