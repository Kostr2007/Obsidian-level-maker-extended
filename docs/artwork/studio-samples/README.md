# Первые образцы иллюстраций Studio

SVG — редактируемые исходники. PNG 1680×975 экспортированы через Inkscape 1.4
(командный режим), не через Canvas Qt. Открыть SVG можно обычным Inkscape.
Исходники созданы программно в SVG; это первые образцы для оценки стиля,
а не завершённый набор иллюстраций для маленького инспектора.

- [Размер уровня](level-size.png) · [SVG](level-size.svg).
- [Количество монстров](monster-quantity.png) · [SVG](monster-quantity.svg).
- [Перепады высоты](steepness.png) · [SVG](steepness.svg).
- [Настоящий скриншот UZDoom + Freedoom](freedoom-reference.png).

Парные схемы условны, не являются настоящими WAD и не доказывают проходимость.
В сравнении количества противников геометрия и снаряжение одинаковы.
Для перепадов показаны лестницы, а не изменение настройки высоты потолков.

Повторный экспорт PNG:

```sh
./scripts/dev/export-illustrations.sh
```

## Установленные инструменты этой облачной среды

- Inkscape 1.4 — уже был установлен в `/usr/bin/inkscape`; экспорт проверен.
- UZDoom 5.0.3 — официальный Linux x86_64 AppImage, распакованный без FUSE.
- Freedoom 0.13.0-2 — пакет Debian trixie; доступны freedoom1.wad / freedoom2.wad.

В этой среде нет sudo; файлы установлены в `/workspace/.obsidian-art-tools`,
отдельно от исходников приложения. Бинарники и IWAD не добавлены в Git.

```sh
source /workspace/.obsidian-art-tools/activate.sh
inkscape docs/artwork/studio-samples/level-size.svg
uzdoom-freedoom +map map01
```

Графические команды требуют работающего DISPLAY. В проверке использован
Xvfb и программный renderer UZDoom. Параметры запуска:

```sh
uzdoom-freedoom -nosound -nomusic -window -width 1280 -height 720 \
  +vid_preferbackend 0 +vid_rendermode 0 +screenblocks 12 +map map01
```

`freedoom-reference.png` — неизменённый захват окна игры, фактический размер
1024×640. Это MAP01 **Hydroelectric Plant** из Freedoom Phase 2, не созданный
Obsidian уровень и не иллюстрация изменения конкретного параметра.

Источник UZDoom:
https://github.com/UZDoom/UZDoom/releases/tag/5.0.3

AppImage SHA-256 проверен по digest официального GitHub release:
`9c5166febc09cbf80c24612a78829037c953f38c4d986e36f8475ddd507e0228`.

Для повторной установки на Ubuntu Inkscape и Freedoom можно установить
через `sudo apt install inkscape freedoom`; UZDoom взять из официального релиза.
Приведённые локальные пути относятся к этой облачной среде, не к компьютеру пользователя.

## Следующий этап

Для игровых сравнений подготовить одну небольшую тестовую сцену и фиксированную
камеру. Для освещения менять только свет, для высоты — только геометрию.
Не сравнивать две случайно сгенерированные карты как доказательство эффекта
одного параметра. Перед размещением в инспекторе упростить иллюстрации под его
ширину, убрать заголовки из картинки в текст Qt, проверить обе темы и масштаб.

Новые схемы — GPL-2.0-or-later, как проект. Скриншот содержит материалы Freedoom:
Copyright 2001–2024 Contributors to the Freedoom project; условия и уведомления
сохранены в [FREEDOOM-COPYRIGHT.txt](FREEDOOM-COPYRIGHT.txt).
