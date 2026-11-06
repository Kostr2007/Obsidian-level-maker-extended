# Встроенные шрифты Inter

В Qt-образец встроены четыре официальных статических TrueType-файла из
[Inter 4.1](https://github.com/rsms/inter/releases/tag/v4.1): Inter Regular (400),
Medium (500), SemiBold (600) и Inter Display SemiBold (600). Они сохраняют полный
набор исходных глифов, включая русский алфавит и Ё/ё. Файлы не изменялись.

Источник: [Inter-4.1.zip](https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip),
`extras/ttf/Inter-Regular.ttf`, `Inter-Medium.ttf`, `Inter-SemiBold.ttf`,
`InterDisplay-SemiBold.ttf`. Внутренняя name-table version всех четырёх файлов —
`Version 4.001;git-9221beed3`; номер официального ZIP-релиза — 4.1.

Copyright (c) 2016 The Inter Project Authors (https://github.com/rsms/inter).
Шрифты распространяются по **SIL Open Font License 1.1**:
[полный неизменённый текст лицензии](INTER-OFL.txt).
[Manifest с источником, размерами, именами и SHA-256](inter-manifest.json).

В source checkout шрифты находятся в
`source_files/qt_frontend/assets/fonts/` и загружаются приложением из Qt-ресурсов.
Полная лицензия и manifest продублированы здесь, чтобы их включала упаковка
`package-linux.sh`, которая копирует `docs/`, а не каталог исходников frontend.
Установка шрифтов в Linux или загрузка по сети во время запуска не требуются.

Роли и принципы использования описаны в [TYPOGRAPHY.md](../../qt6/TYPOGRAPHY.md).

В исходном checkout целостность проверяется без fontTools и других зависимостей:

```sh
python3 scripts/dev/check-font-assets.py
```

Команда сверяет четыре разрешённых файла, безопасные пути, размеры/SHA-256,
источник и лицензию, а также точные копии OFL/manifest в `docs/`. Имена семейства
и наличие нужных глифов проверяются отдельно в QtTest после загрузки шрифтов.
