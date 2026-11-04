//------------------------------------------------------------------------
//  Main Window
//------------------------------------------------------------------------
//
//  OBSIDIAN Level Maker
//
//  Copyright (C) 2021-2022 The OBSIDIAN Team
//  Copyright (C) 2006-2017 Andrew Apted
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//------------------------------------------------------------------------

#include "hdr_fltk.h"
#include "hdr_ui.h"
#include "headers.h"
#include "main.h"
#include <cstdint>

#ifndef WIN32
#include <unistd.h>
#endif

#if (FL_MAJOR_VERSION != 1 || FL_MINOR_VERSION < 3)
#error "Require FLTK version 1.3.0 or later"
#endif

#define BASE_WINDOW_W 960
#define BASE_WINDOW_H 600

UI_MainWin *main_win;

int KF = 0;

int small_font_size;
int header_font_size;

static void main_win_close_CB(Fl_Widget *w, void *data) {
    main_action = MAIN_QUIT;
}

static void main_win_surprise_go_CB(Fl_Widget *w, void *data) {
    main_win->left_mods->SurpriseMe();
    if (main_win->right_mods) {
        main_win->right_mods->SurpriseMe();
    }
    did_randomize = true;
}

static void material_theme_CB(Fl_Widget *, void *data) {
    material_theme = static_cast<int>(reinterpret_cast<intptr_t>(data));
    main_action = MAIN_HARD_RESTART;
}

//
// MainWin Constructor
//
UI_MainWin::UI_MainWin(int W, int H, const char *title)
    : Fl_Double_Window(W, H, title) {
    size_range(W, H, 0, 0, 0, 0, 1);

    callback((Fl_Callback *)main_win_close_CB);

    color(GAP_COLOR, SELECTION);

    const int inset = Material_Enabled() ? kf_w(8) : 0;
    int LEFT_W = kf_w(248);
    int MOD_W = (W - LEFT_W) / 2 - kf_h(4) - inset;

    int TOP_H = kf_h(256);
    int BOT_H = H - TOP_H - kf_h(4);

    menu_bar = new Fl_Menu_Bar(0, 0, W, kf_h(20));
    menu_bar->box(FL_FLAT_BOX);
    menu_bar->textfont(font_style);
    menu_bar->textsize(menu_bar->textsize() * .90);
    menu_bar->add(_("File/Options"), FL_F + 4, menu_do_options);
    menu_bar->add(_("File/Theme"), FL_F + 7, menu_do_theme);
    menu_bar->add(_("File/Set Seed"), FL_F + 5, menu_do_edit_seed);
    menu_bar->add(_("File/Config Manager"), FL_F + 9, menu_do_manage_config);
    menu_bar->add(_("Help/About"), FL_F + 1, menu_do_about);
    menu_bar->add(_("Help/View Logs"), FL_F + 6, menu_do_view_logs);
    menu_bar->add(_("Help/Glossary"), 0, menu_do_glossary);
    menu_bar->add(_("Help/ "), 0, 0, NULL, FL_MENU_INACTIVE);
    menu_bar->add(_("Help/Tutorial"), 0, menu_do_tutorial);
    menu_bar->add(_("Surprise Me/Go"), FL_F + 8, main_win_surprise_go_CB);
    menu_bar->add(_("Appearance/Material You Dark"), 0, material_theme_CB,
                  reinterpret_cast<void *>(intptr_t(1)));
    menu_bar->add(_("Appearance/Material You Light"), 0, material_theme_CB,
                  reinterpret_cast<void *>(intptr_t(2)));
    menu_bar->add(_("Appearance/Classic and Custom"), 0, material_theme_CB,
                  reinterpret_cast<void *>(intptr_t(0)));
    menu_bar->selection_color(SELECTION);

    sizing_group = new Fl_Group(0, kf_h(22), W, H - kf_h(22));
    sizing_group->box(FL_NO_BOX);

    game_box = new UI_Game(inset, kf_h(22) + inset, LEFT_W - inset, TOP_H - kf_h(22) - inset);

    build_box = new UI_Build(inset, TOP_H + kf_h(4), LEFT_W - inset, BOT_H - inset);

    if (single_pane) {
        left_mods = new UI_CustomMods(LEFT_W + kf_h(4), kf_h(22) + inset, W - LEFT_W - kf_h(4) - inset,
                                      H - kf_h(22) - inset * 2);
    } else {
        right_mods =
            new UI_CustomMods(W - MOD_W - inset, kf_h(22) + inset, MOD_W, H - kf_h(22) - inset * 2);

        left_mods =
            new UI_CustomMods(LEFT_W + kf_h(4), kf_h(22) + inset, MOD_W, H - kf_h(22) - inset * 2);
    }

    end();

    resizable(sizing_group);

    end();
}

//
// MainWin Destructor
//
UI_MainWin::~UI_MainWin() {}

void UI_MainWin::CalcWindowSize(int *W, int *H) {
    *W = kf_w(BASE_WINDOW_W);
    *H = kf_h(BASE_WINDOW_H);

    // tweak for "Tiny" setting
    if (KF < 0) {
        *W -= 24;
        *H -= 24;
    }

    //// DEBUG
    //    fprintf(stderr, "\n\nCalcWindowSize --> %d x %d\n", *W, *H);
}

void UI_MainWin::Locked(bool value) {
    if (value) {
        main_win->menu_bar->deactivate();
    } else {
        main_win->menu_bar->activate();
    }
    game_box->Locked(value);
    left_mods->Locked(value);
    if (!single_pane) {
        right_mods->Locked(value);
    }
}

void UI_MainWin::menu_do_about(Fl_Widget *w, void *data) { DLG_AboutText(); }

void UI_MainWin::menu_do_tutorial(Fl_Widget *w, void *data) { DLG_Tutorial(); }

void UI_MainWin::menu_do_view_logs(Fl_Widget *w, void *data) { DLG_ViewLogs(); }

void UI_MainWin::menu_do_glossary(Fl_Widget *w, void *data) {
    DLG_ViewGlossary();
}

void UI_MainWin::menu_do_options(Fl_Widget *w, void *data) {
    DLG_OptionsEditor();
}

void UI_MainWin::menu_do_theme(Fl_Widget *w, void *data) { DLG_ThemeEditor(); }

void UI_MainWin::menu_do_edit_seed(Fl_Widget *w, void *data) { DLG_EditSeed(); }

void UI_MainWin::menu_do_manage_config(Fl_Widget *w, void *data) {
    DLG_ManageConfig();
}
//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
