# Obsidian Extended · Material You

Первый этап редизайна [OBSIDIAN Level Maker](https://github.com/obsidian-level-maker/Obsidian) от [Kostr2007](https://github.com/Kostr2007). Нативный генератор карт Doom с оформлением в духе **Material You / Material Design 3**.

## Оформление

- Тёмная тема по умолчанию и светлая тема с базовой фиолетовой палитрой M3.
- Скруглённые тональные карточки модулей и поля выбора, больше пространства между группами.
- Контрастная основная кнопка Build, спокойная сетка предпросмотра и индикатор фокуса у полей выбора.
- Переключение: **Appearance → Material You Dark / Material You Light / Classic and Custom**. Выбор сохраняется между запусками.
- Старые RGB-темы и редактор **File → Theme (F7)** сохранены. Загрузка старой темы включает её исходное оформление.

![Настоящее приложение: тёмная тема](docs/material-you/dark.png)
![Настоящее приложение: светлая тема](docs/material-you/light.png)

Это первый этап нативного редизайна на FLTK. Автоматического извлечения цвета из обоев, системного переключения темы и анимаций пока нет. Алгоритмы генерации и игровые модули взяты из указанного ниже upstream без изменений.

## Сборка и запуск

Ubuntu / Debian:

```sh
sudo apt install build-essential cmake ninja-build flex libfontconfig1-dev libxft-dev libxinerama-dev libxcursor-dev libgl1-mesa-dev libglu1-mesa-dev
cmake -S . -B build/material -G Ninja -DCMAKE_BUILD_TYPE=Release -DOPTION_USE_WAYLAND=OFF
cmake --build build/material --parallel 2
./obsidian
```

Запускайте из каталога с `data`, `games`, `scripts` и остальными ресурсами. Для NixOS зависимости можно получить через `nix-shell -p cmake ninja gcc flex fontconfig libGL libGLU xorg.libX11 xorg.libXft xorg.libXinerama xorg.libXcursor xorg.libXrender`.

В **Actions → Material You** доступны проверка сборки, тест генерации WAD и архив Linux-приложения с ресурсами. Подробности остальных платформ — [COMPILING.md](COMPILING.md).

## Происхождение и лицензия

Это самостоятельная модификация, не официальный релиз OBSIDIAN. Основа: `obsidian-level-maker/Obsidian`, ветка `obsidian`, commit `f4c93451e10fd3ab13395dfb8e7b0416c1cd6633`. Указанный репозиторий больше не поддерживается авторами; его README указывает на [Obsidian-Content](https://github.com/GTD-Carthage/Obsidian-Content).

Авторы исходной программы: Andrew Apted, The OBSIDIAN Team и участники ObAddon. Их уведомления сохранены в исходниках, [AUTHORS.md](AUTHORS.md) и [оригинальном README](docs/UPSTREAM_README.md). Модификации интерфейса: Kostr2007, ноябрь 2026, с помощью OpenAI Codex. Лицензия программы — [GPL-2.0-or-later](LICENSE.txt); сторонние библиотеки сохраняют свои лицензии.

[Описание реализации и проверок](docs/material-you/IMPLEMENTATION.md)
