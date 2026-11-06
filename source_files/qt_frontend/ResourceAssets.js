// SPDX-License-Identifier: GPL-2.0-or-later
.pragma library
// Original Freedoom Phase 2 sprites. See assets/freedoom/manifest.json.
var assets = [
  {
    "id": "clip",
    "file": "clip.png",
    "caption": "Патроны",
    "option": "ammo"
  },
  {
    "id": "ammo_box",
    "file": "ammo_box.png",
    "caption": "Ящик патронов",
    "option": "ammo"
  },
  {
    "id": "shells",
    "file": "shells.png",
    "caption": "Патроны для дробовика",
    "option": "ammo"
  },
  {
    "id": "shell_box",
    "file": "shell_box.png",
    "caption": "Коробка патронов",
    "option": "ammo"
  },
  {
    "id": "rocket",
    "file": "rocket.png",
    "caption": "Ракета",
    "option": "ammo"
  },
  {
    "id": "rocket_box",
    "file": "rocket_box.png",
    "caption": "Ящик ракет",
    "option": "ammo"
  },
  {
    "id": "cell",
    "file": "cell.png",
    "caption": "Энергетическая ячейка",
    "option": "ammo"
  },
  {
    "id": "cell_pack",
    "file": "cell_pack.png",
    "caption": "Блок ячеек",
    "option": "ammo"
  },
  {
    "id": "stimpack",
    "file": "stimpack.png",
    "caption": "Малая аптечка",
    "option": "health"
  },
  {
    "id": "medikit",
    "file": "medikit.png",
    "caption": "Большая аптечка",
    "option": "health"
  },
  {
    "id": "health_bonus",
    "file": "health_bonus.png",
    "caption": "Бонус здоровья",
    "option": "health"
  },
  {
    "id": "green_armor",
    "file": "green_armor.png",
    "caption": "Лёгкая броня",
    "option": "items"
  },
  {
    "id": "blue_armor",
    "file": "blue_armor.png",
    "caption": "Усиленная броня",
    "option": "items"
  },
  {
    "id": "armor_bonus",
    "file": "armor_bonus.png",
    "caption": "Бонус брони",
    "option": "items"
  },
  {
    "id": "shotgun",
    "file": "shotgun.png",
    "caption": "Дробовик",
    "option": "weapons"
  },
  {
    "id": "super_shotgun",
    "file": "super_shotgun.png",
    "caption": "Двуствольный дробовик",
    "option": "weapons"
  },
  {
    "id": "chaingun",
    "file": "chaingun.png",
    "caption": "Пулемёт",
    "option": "weapons"
  },
  {
    "id": "rocket_launcher",
    "file": "rocket_launcher.png",
    "caption": "Ракетное оружие",
    "option": "weapons"
  },
  {
    "id": "plasma_rifle",
    "file": "plasma_rifle.png",
    "caption": "Плазменное оружие",
    "option": "weapons"
  },
  {
    "id": "bfg",
    "file": "bfg.png",
    "caption": "Тяжёлое энергооружие",
    "option": "weapons"
  },
  {
    "id": "chainsaw",
    "file": "chainsaw.png",
    "caption": "Бензопила",
    "option": "weapons"
  },
  {
    "id": "soul_bonus",
    "file": "soul_bonus.png",
    "caption": "Особая награда",
    "option": "secrets_bonus"
  }
];

function forOption(key, game) {
    return assets.filter(function(a) {
        return a.option === key && !(a.id === "super_shotgun" && (game === "doom1" || game === "ultdoom"));
    });
}
function image(file) { return "qrc:/freedoom/"+file; }
function compatible(game) { return ["doom1","doom2","ultdoom","tnt","plutonia"].indexOf(game)>=0; }
