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
#include <algorithm>

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

static void material_accent_CB(Fl_Widget *, void *data) {
    material_accent = static_cast<int>(reinterpret_cast<intptr_t>(data));
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

    if (Material_Enabled()) {
        menu_bar->add(_("Appearance/Accent/Violet"), 0, material_accent_CB, reinterpret_cast<void *>(intptr_t(0)));
        menu_bar->add(_("Appearance/Accent/Sage"), 0, material_accent_CB, reinterpret_cast<void *>(intptr_t(1)));
        menu_bar->add(_("Appearance/Accent/Ocean"), 0, material_accent_CB, reinterpret_cast<void *>(intptr_t(2)));
        menu_bar->add(_("Appearance/Accent/Clay"), 0, material_accent_CB, reinterpret_cast<void *>(intptr_t(3)));
        workspace_title = new Fl_Box(0, 0, 1, 1, _("Make something worth exploring."));
        workspace_title->labelfont(font_style | FL_BOLD);
        workspace_title->labelsize(FL_NORMAL_SIZE + 10);
        workspace_title->align(FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        workspace_hint = new Fl_Box(0, 0, 1, 1, _("Obsidian Extended  /  Your next world starts here"));
        workspace_hint->labelsize(small_font_size);
        workspace_hint->align(FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        rail = new Fl_Group(0, 0, 1, 1);
        rail->color(GAP_COLOR);
        const char *labels[] = {single_pane ? _("All settings") : _("World"), _("Gameplay"), _("Preview")};
        for (int i = 0; i < 3; ++i) {
            nav[i] = new UI_MaterialButton(0, 0, 1, 1, labels[i]);
            nav[i]->type(FL_TOGGLE_BUTTON);
            nav[i]->callback(section_CB, this);
            nav[i]->tooltip(i == 0 ? _("Architecture, layout and map options") :
                            i == 1 ? _("Combat, items and optional modules") : _("Map preview and generation status"));
        }
        auto *presets = new UI_MaterialButton(0, 0, 1, 1, _("Presets"));
        presets->callback(menu_do_manage_config);
        auto *options = new UI_MaterialButton(0, 0, 1, 1, _("Options"));
        options->callback(menu_do_options);
        auto *seed = new UI_MaterialButton(0, 0, 1, 1, _("Set seed"));
        seed->callback(menu_do_edit_seed);
        auto *shuffle = new UI_MaterialButton(0, 0, 1, 1, _("Surprise me"));
        shuffle->callback(main_win_surprise_go_CB);
        rail->end();
        game_box = new UI_Game(0, 0, kf_w(264), kf_h(500));
        build_box = new UI_Build(0, 0, kf_w(264), kf_h(500));
        // Keep both Lua-owned module collections intact; navigation only
        // changes which collection is visible, never generator configuration.
        left_mods = new UI_CustomMods(0, 0, kf_w(420), kf_h(500));
        if (!single_pane) right_mods = new UI_CustomMods(0, 0, kf_w(420), kf_h(500));
        section_title = new Fl_Box(0, 0, 1, 1);
        section_title->labelfont(font_style | FL_BOLD);
        section_title->labelsize(header_font_size + 2);
        section_title->align(FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        search = new Fl_Input(0, 0, 1, 1, _("Find settings"));
        search->align(FL_ALIGN_TOP_LEFT);
        search->box(Material_ControlBox());
        search->color(BUTTON_COLOR);
        search->textcolor(FONT_COLOR);
        search->cursor_color(SELECTION);
        search->textfont(font_style);
        search->textsize(FL_NORMAL_SIZE);
        search->when(FL_WHEN_CHANGED);
        search->callback(search_CB, this);
        search->tooltip(_("Search card titles and option names in this section. Ctrl+F to focus."));
        sizing_group = nullptr;
        end();
        resizable(this);
        size_range(kf_w(840), kf_h(560));
        LayoutMaterial();
        return;
    }

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
    if (Material_Enabled()) {
        *W = std::min(kf_w(1280), Fl::w() - 40);
        *H = std::min(kf_h(740), Fl::h() - 64);
        return;
    }
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
    if (rail) {
        if (value) { rail->deactivate(); search->deactivate(); }
        else { rail->activate(); search->activate(); }
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

void UI_MainWin::section_CB(Fl_Widget *widget, void *data) {
    auto *win = static_cast<UI_MainWin *>(data);
    for (int i = 0; i < 3; ++i) if (widget == win->nav[i]) win->SelectSection(i);
}

void UI_MainWin::search_CB(Fl_Widget *, void *data) {
    auto *win = static_cast<UI_MainWin *>(data);
    win->left_mods->Filter(win->search->value());
    if (win->right_mods) win->right_mods->Filter(win->search->value());
}

void UI_MainWin::SelectSection(int value) {
    section = value;
    LayoutMaterial();
    redraw();
}

void UI_MainWin::resize(int X, int Y, int W, int H) {
    if (!rail) { Fl_Double_Window::resize(X, Y, W, H); return; }
    // Explicit layout keeps fixed-width controls stable across breakpoints.
    resizable(nullptr);
    Fl_Double_Window::resize(X, Y, W, H);
    resizable(this);
    LayoutMaterial();
}

void UI_MainWin::LayoutMaterial() {
    const int gap = kf_w(12), rw = kf_w(108), gw = kf_w(244);
    const int top = kf_h(100), bottom = h() - gap;
    const int cx = rw + gw + gap * 3;
    const bool wide = w() >= kf_w(1040);
    const int pw = kf_w(264);
    const int cw = w() - cx - gap - (wide ? pw + gap : 0);
    menu_bar->resize(0, 0, w(), kf_h(24));
    workspace_title->resize(gap, kf_h(30), w() - gap * 2, kf_h(34));
    workspace_hint->resize(gap + 2, kf_h(66), w() - gap * 2, kf_h(24));
    rail->resize(gap, top, rw, bottom - top);
    for (int i = 0; i < rail->children(); ++i)
        rail->child(i)->resize(gap, top + i * kf_h(48), rw, kf_h(40));
    if (single_pane) nav[1]->hide();
    for (int i = 0; i < 3; ++i) nav[i]->value(section == i);
    game_box->resize(rw + gap * 2, top, gw, bottom - top);
    section_title->copy_label(section == 0 ? (single_pane ? _("All settings") : _("Shape your world")) :
                              section == 1 ? _("Set the challenge") : _("Your map, taking shape"));
    section_title->resize(cx, top, cw, kf_h(32));
    search->resize(cx, top + kf_h(60), cw, kf_h(36));
    const int list_y = top + kf_h(112);
    auto place = [](Fl_Widget *widget, int x, int y, int w, int h) { widget->resize(x, y, w, h); };
    place(left_mods, cx, list_y, cw, bottom - list_y);
    if (right_mods) place(right_mods, cx, list_y, cw, bottom - list_y);
    left_mods->hide();
    if (right_mods) right_mods->hide();
    search->show();
    if (section == 0) left_mods->show();
    if (section == 1 && right_mods) right_mods->show();
    if (section == 2) search->hide();
    if (section == 2) {
        place(build_box, cx, top + kf_h(44), w() - cx - gap, bottom - top - kf_h(44));
        build_box->show();
    } else if (wide) {
        place(build_box, w() - pw - gap, top, pw, bottom - top);
        build_box->show();
    } else build_box->hide();
}

int UI_MainWin::handle(int event) {
    if (rail && rail->active() && event == FL_SHORTCUT && Fl::event_command() && Fl::event_key() == 'f') {
        if (section == 2) SelectSection(0);
        search->take_focus();
        return 1;
    }
    return Fl_Double_Window::handle(event);
}
