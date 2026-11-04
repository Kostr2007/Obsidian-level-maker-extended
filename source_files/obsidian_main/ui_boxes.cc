// Modified box types from the FLTK defaults to account for custom border
// colors/gradients. -Dasho

#include <FL/Fl.H>
#include <FL/fl_draw.H>
#include "main.h"

void c_color(Fl_Color c) { Fl::set_box_color(c); }

static const uchar c_active_ramp[24] = {
    FL_GRAY_RAMP + 0,  FL_GRAY_RAMP + 1,  FL_GRAY_RAMP + 2,  FL_GRAY_RAMP + 3,
    FL_GRAY_RAMP + 4,  FL_GRAY_RAMP + 5,  FL_GRAY_RAMP + 6,  FL_GRAY_RAMP + 7,
    FL_GRAY_RAMP + 8,  FL_GRAY_RAMP + 9,  FL_GRAY_RAMP + 10, FL_GRAY_RAMP + 11,
    FL_GRAY_RAMP + 12, FL_GRAY_RAMP + 13, FL_GRAY_RAMP + 14, FL_GRAY_RAMP + 15,
    FL_GRAY_RAMP + 16, FL_GRAY_RAMP + 17, FL_GRAY_RAMP + 18, FL_GRAY_RAMP + 19,
    FL_GRAY_RAMP + 20, FL_GRAY_RAMP + 21, FL_GRAY_RAMP + 22, FL_GRAY_RAMP + 23};
static const uchar c_inactive_ramp[24] = {43, 43, 44, 44, 44, 45, 45, 46,
                                          46, 46, 47, 47, 48, 48, 48, 49,
                                          49, 49, 50, 50, 51, 51, 52, 52};
static int c_draw_it_active = 1;

const uchar *c_fl_gray_ramp() {
    return (c_draw_it_active ? c_active_ramp : c_inactive_ramp) - 'A';
}

// CUSTOM OXY BOXES
// ---------------------------------------------------------------------------------------

void coxy_up_box(int x, int y, int w, int h, Fl_Color bg) {
  float gradoffset = 0.45; // Formerly GROFF
  float stepoffset = (1.0 / (float)h);
  int xw = x + w - 1;
  //    from bottom to top
  for (int _y = y; _y < y + h; _y++) {
    fl_color(fl_color_average(bg, GRADIENT_COLOR, (gradoffset < 1.0) ? gradoffset : 1.0));
    fl_xyline(x, _y, xw);
    gradoffset += stepoffset;
  }
}

void coxy_down_box(int x, int y, int w, int h, Fl_Color bg) {
  float gradoffset = 0.45; // Formerly GROFF
  float stepoffset = (1.0 / (float)h);
  int xw = x + w - 1;
  //    from top to bottom
  for (int _y = y + h - 1; _y >= y; _y--) {
    fl_color(fl_color_average(bg, GRADIENT_COLOR, (gradoffset < 1.0) ? gradoffset : 1.0));
    fl_xyline(x, _y, xw);
    gradoffset += stepoffset;
  }
}

// CUSTOM GLEAM BOXES
// ---------------------------------------------------------------------------------------

void cgleam_shade_rect_top_bottom(int x, int y, int w, int h, Fl_Color fg1,
                                  Fl_Color fg2, float th) {
    // calculate background size w/o borders
    x += 2;
    y += 2;
    w -= 4;
    h -= 4;
    // draw the shiny background using maximum limits
    int h_top = ((h / 2) < (20) ? (h / 2) : (20));     // min(h/2, 20);
    int h_bottom = ((h / 6) < (15) ? (h / 6) : (15));  // min(h/6, 15);
    int h_flat = h - h_top - h_bottom;
    float step_size_top = h_top > 1 ? (0.999f / float(h_top)) : 1;
    float step_size_bottom = h_bottom > 1 ? (0.999f / float(h_bottom)) : 1;
    // draw the gradient at the top of the widget
    float k = 1;
    for (int i = 0; i < h_top; i++, k -= step_size_top) {
        c_color(fl_color_average(fl_color_average(fg1, fg2, th), fg1, k));
        fl_xyline(x, y + i, x + w - 1);
    }

    // draw a "flat" rectangle in the middle area of the box
    c_color(fg1);
    fl_rectf(x, y + h_top, w, h_flat);

    // draw the gradient at the bottom of the widget
    k = 1;
    for (int i = 0; i < h_bottom; i++, k -= step_size_bottom) {
        c_color(fl_color_average(fg1, fl_color_average(fg1, fg2, th), k));
        fl_xyline(x, y + h_top + h_flat + i, x + w - 1);
    }
}

// See shade_rect_top_bottom()
void cgleam_shade_rect_top_bottom_up(int x, int y, int w, int h, Fl_Color bc,
                                     float th) {
    cgleam_shade_rect_top_bottom(x, y, w, h, bc, GRADIENT_COLOR, th);
}

// See shade_rect_top_bottom()
void cgleam_shade_rect_top_bottom_down(int x, int y, int w, int h, Fl_Color bc,
                                       float th) {
    cgleam_shade_rect_top_bottom(x, y, w, h, bc, GRADIENT_COLOR, th);
}

// Draw box borders. Color arguments:
// - fg1: outer border line (left, right, top, bottom)
// - fg2: inner border line (left, right)
// - lc : inner border line (top, bottom)

void cgleam_frame_rect(int x, int y, int w, int h, Fl_Color fg1, Fl_Color fg2,
                       Fl_Color lc) {
    // outer border line:
    c_color(fg1);
    fl_xyline(x + 1, y, x + w - 2);          // top
    fl_yxline(x + w - 1, y + 1, y + h - 2);  // right
    fl_xyline(x + 1, y + h - 1, x + w - 2);  // bottom
    fl_yxline(x, y + 1, y + h - 2);          // left

    // inner border line (left, right):
    c_color(fg2);
    fl_yxline(x + 1, y + 2, y + h - 3);      // left
    fl_yxline(x + w - 2, y + 2, y + h - 3);  // right

    // inner border line (top, bottom):
    c_color(lc);
    fl_xyline(x + 2, y + 1, x + w - 3);      // top
    fl_xyline(x + 2, y + h - 2, x + w - 3);  // bottom
}

// Draw box borders with different colors (up/down effect).

void cgleam_frame_rect_up(int x, int y, int w, int h, Fl_Color bc, Fl_Color lc,
                          float th1, float th2) {
    cgleam_frame_rect(x, y, w, h, bc, lc, lc);
}

void cgleam_frame_rect_down(int x, int y, int w, int h, Fl_Color bc,
                            Fl_Color lc, float th1, float th2) {
    cgleam_frame_rect(x, y, w, h, fl_color_average(bc, fl_lighter(bc), th1),
                      fl_color_average(fl_darker(bc), bc, th2), lc);
}

// Draw the different box types. These are the actual box drawing functions.

void cgleam_up_box(int x, int y, int w, int h, Fl_Color c) {
    cgleam_shade_rect_top_bottom_up(x, y, w, h, c, .15f);
    cgleam_frame_rect_up(x, y, w, h, BORDER_COLOR, BORDER_COLOR, .15f, .05f);
}

void cgleam_thin_up_box(int x, int y, int w, int h, Fl_Color c) {
    cgleam_shade_rect_top_bottom_up(x, y, w, h, c, .25f);
    cgleam_frame_rect_up(x, y, w, h, BORDER_COLOR, BORDER_COLOR, .25f, .15f);
}

void cgleam_down_box(int x, int y, int w, int h, Fl_Color c) {
    cgleam_shade_rect_top_bottom_down(x, y, w, h, c, .65f);
    cgleam_frame_rect_down(x, y, w, h, BORDER_COLOR, BORDER_COLOR, .05f, .95f);
}

// CUSTOM GTK BOXES
// ---------------------------------------------------------------------------------------

void cgtk_up_frame(int x, int y, int w, int h, Fl_Color c) {
    c_color(fl_color_average(fl_lighter(c), c, 0.5));
    fl_xyline(x + 2, y + 1, x + w - 3);
    fl_yxline(x + 1, y + 2, y + h - 3);

    c_color(fl_color_average(fl_darker(c), c, 0.5));
    fl_begin_loop();
    fl_vertex(x, y + 2);
    fl_vertex(x + 2, y);
    fl_vertex(x + w - 3, y);
    fl_vertex(x + w - 1, y + 2);
    fl_vertex(x + w - 1, y + h - 3);
    fl_vertex(x + w - 3, y + h - 1);
    fl_vertex(x + 2, y + h - 1);
    fl_vertex(x, y + h - 3);
    fl_end_loop();
}

void cgtk_up_box(int x, int y, int w, int h, Fl_Color c) {
    cgtk_up_frame(x, y, w, h, c);

    c_color(fl_color_average(fl_lighter(c), c, 0.4f));
    fl_xyline(x + 2, y + 2, x + w - 3);
    c_color(fl_color_average(fl_lighter(c), c, 0.2f));
    fl_xyline(x + 2, y + 3, x + w - 3);
    c_color(fl_color_average(fl_lighter(c), c, 0.1f));
    fl_xyline(x + 2, y + 4, x + w - 3);
    c_color(c);
    fl_rectf(x + 2, y + 5, w - 4, h - 7);
    c_color(fl_color_average(fl_darker(c), c, 0.025f));
    fl_xyline(x + 2, y + h - 4, x + w - 3);
    c_color(fl_color_average(fl_darker(c), c, 0.05f));
    fl_xyline(x + 2, y + h - 3, x + w - 3);
    c_color(fl_color_average(fl_darker(c), c, 0.1f));
    fl_xyline(x + 2, y + h - 2, x + w - 3);
    fl_yxline(x + w - 2, y + 2, y + h - 3);
}

void cgtk_down_frame(int x, int y, int w, int h, Fl_Color c) {
    c_color(fl_color_average(fl_darker(c), c, 0.5));
    fl_begin_loop();
    fl_vertex(x, y + 2);
    fl_vertex(x + 2, y);
    fl_vertex(x + w - 3, y);
    fl_vertex(x + w - 1, y + 2);
    fl_vertex(x + w - 1, y + h - 3);
    fl_vertex(x + w - 3, y + h - 1);
    fl_vertex(x + 2, y + h - 1);
    fl_vertex(x, y + h - 3);
    fl_end_loop();

    c_color(fl_color_average(fl_darker(c), c, 0.1f));
    fl_xyline(x + 2, y + 1, x + w - 3);
    fl_yxline(x + 1, y + 2, y + h - 3);

    c_color(fl_color_average(fl_darker(c), c, 0.05f));
    fl_yxline(x + 2, y + h - 2, y + 2, x + w - 2);
}

void cgtk_down_box(int x, int y, int w, int h, Fl_Color c) {
    cgtk_down_frame(x, y, w, h, c);

    c_color(c);
    fl_rectf(x + 3, y + 3, w - 5, h - 4);
    fl_yxline(x + w - 2, y + 3, y + h - 3);
}

void cgtk_thin_up_frame(int x, int y, int w, int h, Fl_Color c) {
    c_color(fl_color_average(fl_lighter(c), c, 0.6f));
    fl_xyline(x + 1, y, x + w - 2);
    fl_yxline(x, y + 1, y + h - 2);

    c_color(fl_color_average(fl_darker(c), c, 0.4f));
    fl_xyline(x + 1, y + h - 1, x + w - 2);
    fl_yxline(x + w - 1, y + 1, y + h - 2);
}

void cgtk_thin_up_box(int x, int y, int w, int h, Fl_Color c) {
    cgtk_thin_up_frame(x, y, w, h, c);

    c_color(fl_color_average(fl_lighter(c), c, 0.4f));
    fl_xyline(x + 1, y + 1, x + w - 2);
    c_color(fl_color_average(fl_lighter(c), c, 0.2f));
    fl_xyline(x + 1, y + 2, x + w - 2);
    c_color(fl_color_average(fl_lighter(c), c, 0.1f));
    fl_xyline(x + 1, y + 3, x + w - 2);
    c_color(c);
    fl_rectf(x + 1, y + 4, w - 2, h - 8);
    c_color(fl_color_average(fl_darker(c), c, 0.025f));
    fl_xyline(x + 1, y + h - 4, x + w - 2);
    c_color(fl_color_average(fl_darker(c), c, 0.05f));
    fl_xyline(x + 1, y + h - 3, x + w - 2);
    c_color(fl_color_average(fl_darker(c), c, 0.1f));
    fl_xyline(x + 1, y + h - 2, x + w - 2);
}

// CUSTOM PLASTIC BOXES
// ---------------------------------------------------------------------------------------

Fl_Color cplastic_shade_color(uchar gc, Fl_Color bc) {
    return fl_color_average((Fl_Color)gc, bc, 0.50f);
}

void cplastic_frame_rect(int x, int y, int w, int h, const char *c,
                         Fl_Color bc) {
    const uchar *g = c_fl_gray_ramp();
    int b = ((int)strlen(c)) / 4 + 1;

    for (x += b, y += b, w -= 2 * b, h -= 2 * b; b > 1; b--) {
        // Draw lines around the perimeter of the button, 4 colors per
        // circuit.
        fl_color(cplastic_shade_color(g[(int)*c++], bc));
        fl_line(x, y + h + b, x + w - 1, y + h + b, x + w + b - 1, y + h);
        fl_color(cplastic_shade_color(g[(int)*c++], bc));
        fl_line(x + w + b - 1, y + h, x + w + b - 1, y, x + w - 1, y - b);
        fl_color(cplastic_shade_color(g[(int)*c++], bc));
        fl_line(x + w - 1, y - b, x, y - b, x - b, y);
        fl_color(cplastic_shade_color(g[(int)*c++], bc));
        fl_line(x - b, y, x - b, y + h, x, y + h + b);
    }
}

void cplastic_shade_rect(int x, int y, int w, int h, const char *c,
                         Fl_Color bc) {
    const uchar *g = c_fl_gray_ramp();
    int i, j;
    int clen = (int)strlen(c) - 1;
    int chalf = clen / 2;
    int cstep = 1;

    if (h < (w * 2)) {
        // Horizontal shading...
        if (clen >= h) {
            cstep = 2;
        }

        for (i = 0, j = 0; j < chalf; i++, j += cstep) {
            // Draw the top line and points...
            fl_color(cplastic_shade_color(g[(int)c[i]], bc));
            fl_xyline(x + 1, y + i, x + w - 2);

            fl_color(cplastic_shade_color(g[c[i] - 2], bc));
            fl_point(x, y + i + 1);
            fl_point(x + w - 1, y + i + 1);

            // Draw the bottom line and points...
            fl_color(cplastic_shade_color(g[(int)c[clen - i]], bc));
            fl_xyline(x + 1, y + h - i, x + w - 2);

            fl_color(cplastic_shade_color(g[c[clen - i] - 2], bc));
            fl_point(x, y + h - i);
            fl_point(x + w - 1, y + h - i);
        }

        // Draw the interior and sides...
        i = chalf / cstep;

        fl_color(cplastic_shade_color(g[(int)c[chalf]], bc));
        fl_rectf(x + 1, y + i, w - 2, h - 2 * i + 1);

        fl_color(cplastic_shade_color(g[c[chalf] - 2], bc));
        fl_yxline(x, y + i, y + h - i);
        fl_yxline(x + w - 1, y + i, y + h - i);
    } else {
        // Vertical shading...
        if (clen >= w) {
            cstep = 2;
        }

        for (i = 0, j = 0; j < chalf; i++, j += cstep) {
            // Draw the left line and points...
            fl_color(cplastic_shade_color(g[(int)c[i]], bc));
            fl_yxline(x + i, y + 1, y + h - 1);

            fl_color(cplastic_shade_color(g[c[i] - 2], bc));
            fl_point(x + i + 1, y);
            fl_point(x + i + 1, y + h);

            // Draw the right line and points...
            fl_color(cplastic_shade_color(g[(int)c[clen - i]], bc));
            fl_yxline(x + w - 1 - i, y + 1, y + h - 1);

            fl_color(cplastic_shade_color(g[c[clen - i] - 2], bc));
            fl_point(x + w - 2 - i, y);
            fl_point(x + w - 2 - i, y + h);
        }

        // Draw the interior, top, and bottom...
        i = chalf / cstep;

        fl_color(cplastic_shade_color(g[(int)c[chalf]], bc));
        fl_rectf(x + i, y + 1, w - 2 * i, h - 1);

        fl_color(cplastic_shade_color(g[c[chalf] - 2], bc));
        fl_xyline(x + i, y, x + w - i);
        fl_xyline(x + i, y + h, x + w - i);
    }
}

void cplastic_up_frame(int x, int y, int w, int h, Fl_Color c) {
    cplastic_frame_rect(x, y, w, h - 1, "KLDIIJLM", BORDER_COLOR);
}

void cplastic_narrow_thin_box(int x, int y, int w, int h, Fl_Color c) {
    if (h <= 0 || w <= 0) {
        return;
    }
    const uchar *g = c_fl_gray_ramp();
    fl_color(cplastic_shade_color(g[(int)'R'], c));
    fl_rectf(x + 1, y + 1, w - 2, h - 2);
    fl_color(cplastic_shade_color(g[(int)'I'], c));
    if (w > 1) {
        fl_xyline(x + 1, y, x + w - 2);
        fl_xyline(x + 1, y + h - 1, x + w - 2);
    }
    if (h > 1) {
        fl_yxline(x, y + 1, y + h - 2);
        fl_yxline(x + w - 1, y + 1, y + h - 2);
    }
}

void cplastic_thin_up_box(int x, int y, int w, int h, Fl_Color c) {
    if (w > 4 && h > 4) {
        cplastic_shade_rect(x + 1, y + 1, w - 2, h - 3, "RQOQSUWQ", c);
        cplastic_frame_rect(x, y, w, h - 1, "IJLM", BORDER_COLOR);
    } else {
        cplastic_narrow_thin_box(x, y, w, h, c);
    }
}

void cplastic_up_box(int x, int y, int w, int h, Fl_Color c) {
    if (w > 8 && h > 8) {
        cplastic_shade_rect(x + 1, y + 1, w - 2, h - 3, "RVQNOPQRSTUVWVQ", c);
        cplastic_frame_rect(x, y, w, h - 1, "IJLM", BORDER_COLOR);
    } else {
        cplastic_thin_up_box(x, y, w, h, c);
    }
}

void cplastic_down_frame(int x, int y, int w, int h, Fl_Color c) {
    cplastic_frame_rect(x, y, w, h - 1, "LLLLTTRR", BORDER_COLOR);
}

void cplastic_down_box(int x, int y, int w, int h, Fl_Color c) {
    if (w > 6 && h > 6) {
        cplastic_shade_rect(x + 2, y + 2, w - 4, h - 5, "STUVWWWVT", c);
        cplastic_down_frame(x, y, w, h, BORDER_COLOR);
    } else {
        cplastic_narrow_thin_box(x, y, w, h, c);
    }
}

// CUSTOM SHADOW BOX
// ---------------------------------------------------------------------------------------

#define BW 3

void cshadow_frame(int x, int y, int w, int h, Fl_Color c) {
    fl_color(fl_darker(GRADIENT_COLOR));
    fl_rectf(x + BW, y + h - BW, w - BW, BW);
    fl_rectf(x + w - BW, y + BW, BW, h - BW);
    Fl::set_box_color(c);
    fl_rect(x, y, w - BW, h - BW);
}

void cshadow_box(int x, int y, int w, int h, Fl_Color c) {
    Fl::set_box_color(c);
    fl_rectf(x + 1, y + 1, w - 2 - BW, h - 2 - BW);
    cshadow_frame(x, y, w, h, GRADIENT_COLOR);
}

// CUSTOM BORDER BOX
// ---------------------------------------------------------------------------------------

void crectbound(int x, int y, int w, int h, Fl_Color bgcolor) {
    Fl::set_box_color(BORDER_COLOR);
    fl_rect(x, y, w, h);
    Fl::set_box_color(bgcolor);
    fl_rectf(x + 1, y + 1, w - 2, h - 2);
}

// CUSTOM NORMAL BOXES
// ---------------------------------------------------------------------------------------

void cframe(int x, int y, int w, int h) {
    if (h > 0 && w > 0) {
        // draw top line:
        fl_color(BORDER_COLOR);
        fl_xyline(x, y, x + w - 1);
        y++;
        // draw left line:
        fl_color(BORDER_COLOR);
        fl_yxline(x, y + h - 1, y);
        x++;
        // draw bottom line:
        fl_color(BORDER_COLOR);
        fl_xyline(x, y + h - 1, x + w - 1);
        // draw right line:
        fl_color(BORDER_COLOR);
        fl_yxline(x + w - 1, y + h - 1, y);
    }
}

void cframe2(int x, int y, int w, int h) {
    if (h > 0 && w > 0) {
        // draw bottom line:
        fl_color(BORDER_COLOR);
        fl_xyline(x, y + h - 1, x + w - 1);
        // draw right line:
        fl_color(BORDER_COLOR);
        fl_yxline(x + w - 1, y + h - 1, y);
        // draw top line:
        fl_color(BORDER_COLOR);
        fl_xyline(x, y, x + w - 1);
        y++;
        // draw left line:
        fl_color(BORDER_COLOR);
        fl_yxline(x, y + h - 1, y);
        x++;
    }
}

void cframe3(const char *s, int x, int y, int w, int h) {
    const uchar *g = c_fl_gray_ramp();
    if (h > 0 && w > 0) {
        for (; *s;) {
            // draw bottom line:
            fl_color(g[(int)*s++]);
            fl_xyline(x, y + h - 1, x + w - 1);
            if (--h <= 0) {
                break;
            }
            // draw right line:
            fl_color(g[(int)*s++]);
            fl_yxline(x + w - 1, y + h - 1, y);
            if (--w <= 0) {
                break;
            }
            // draw top line:
            fl_color(g[(int)*s++]);
            fl_xyline(x, y, x + w - 1);
            y++;
            if (--h <= 0) {
                break;
            }
            // draw left line:
            fl_color(g[(int)*s++]);
            fl_yxline(x, y + h - 1, y);
            x++;
            if (--w <= 0) {
                break;
            }
        }
    }
}

/** Draws a frame of type FL_THIN_UP_FRAME */
void cthin_up_frame(int x, int y, int w, int h, Fl_Color) {
    cframe2(x, y, w, h);
}

/** Draws a box of type FL_THIN_UP_BOX */
void cthin_up_box(int x, int y, int w, int h, Fl_Color c) {
    cthin_up_frame(x, y, w, h, BORDER_COLOR);
    Fl::set_box_color(c);
    fl_rectf(x + 1, y + 1, w - 2, h - 2);
}

/** Draws a frame of type FL_UP_FRAME */
void cup_frame(int x, int y, int w, int h, Fl_Color) { cframe2(x, y, w, h); }

/** Draws a box of type FL_UP_BOX */
void cup_box(int x, int y, int w, int h, Fl_Color c) {
    cup_frame(x, y, w, h, BORDER_COLOR);
    Fl::set_box_color(c);
    fl_rectf(x + 2, y + 2, w - 4, h - 4);
}

/** Draws a frame of type FL_DOWN_FRAME */
void cdown_frame(int x, int y, int w, int h, Fl_Color) { cframe2(x, y, w, h); }

/** Draws a box of type FL_DOWN_BOX */
void cdown_box(int x, int y, int w, int h, Fl_Color c) {
    cdown_frame(x, y, w, h, BORDER_COLOR);
    Fl::set_box_color(c);
    fl_rectf(x + 2, y + 2, w - 4, h - 4);
}

/** Draws a frame of type FL_ENGRAVED_FRAME */
void cengraved_frame(int x, int y, int w, int h, Fl_Color) {
    cframe3("HHWWWWHH", x, y, w, h);
}

/** Draws a box of type FL_ENGRAVED_BOX */
void cengraved_box(int x, int y, int w, int h, Fl_Color c) {
    cengraved_frame(x, y, w, h, BORDER_COLOR);
    Fl::set_box_color(c);
    fl_rectf(x + 2, y + 2, w - 4, h - 4);
}

/** Draws a frame of type FL_EMBOSSED_FRAME */
void cembossed_frame(int x, int y, int w, int h, Fl_Color) {
    cframe(x, y, w, h);
}

/** Draws a box of type FL_EMBOSSED_BOX */
void cembossed_box(int x, int y, int w, int h, Fl_Color c) {
    cembossed_frame(x, y, w, h, BORDER_COLOR);
    Fl::set_box_color(c);
    fl_rectf(x + 2, y + 2, w - 4, h - 4);
}

// Material You foundation for Obsidian Extended (2026).
// Tonal roles use the baseline M3 purple palette. User RGB themes remain available.
#include <algorithm>

bool Material_Enabled() { return material_theme == 1 || material_theme == 2; }

Fl_Boxtype Material_CardBox() {
    return static_cast<Fl_Boxtype>(FL_FREE_BOXTYPE + 4);
}
Fl_Boxtype Material_ControlBox() {
    return static_cast<Fl_Boxtype>(FL_FREE_BOXTYPE + 5);
}
Fl_Color Material_OnPrimary() {
    return material_theme == 2 ? fl_rgb_color(255, 255, 255)
                               : fl_rgb_color(22, 32, 35);
}

static void material_card(int x, int y, int w, int h, Fl_Color c) {
    if (w <= 0 || h <= 0) return;
    fl_color(GAP_COLOR);
    fl_rectf(x, y, w, h);
    fl_color(Fl::draw_box_active() ? c : fl_inactive(c));
    fl_rounded_rectf(x, y, w, h, std::min(18, (std::min(w, h) - 1) / 2));
}

static void material_control(int x, int y, int w, int h, Fl_Color c) {
    if (w <= 0 || h <= 0) return;
    fl_color(WINDOW_BG);
    fl_rectf(x, y, w, h);
    fl_color(Fl::draw_box_active() ? c : fl_inactive(c));
    fl_rounded_rectf(x, y, w, h, std::min(12, (std::min(w, h) - 1) / 2));
}

static void material_pressed(int x, int y, int w, int h, Fl_Color c) {
    material_control(x, y, w, h, fl_color_average(c, SELECTION, 0.88f));
}

void Material_Setup() {
    const bool light = material_theme == 2;
    FONT_COLOR = light ? fl_rgb_color(29, 27, 32) : fl_rgb_color(230, 224, 233);
    FONT2_COLOR = FONT_COLOR;
    SELECTION = light ? fl_rgb_color(103, 80, 164) : fl_rgb_color(208, 188, 255);
    WINDOW_BG = light ? fl_rgb_color(243, 237, 247) : fl_rgb_color(33, 31, 38);
    GAP_COLOR = light ? fl_rgb_color(254, 247, 255) : fl_rgb_color(20, 18, 24);
    BUTTON_COLOR = light ? fl_rgb_color(232, 222, 248) : fl_rgb_color(54, 48, 65);
    BORDER_COLOR = light ? fl_rgb_color(121, 116, 126) : fl_rgb_color(147, 143, 153);
    // Curated tonal schemes. These are deliberately named presets, not a
    // substitute for Material Color Utilities' dynamic color generation.
    if (material_accent == 1) { // Sage
        SELECTION = light ? fl_rgb_color(56, 106, 78) : fl_rgb_color(157, 213, 174);
        BUTTON_COLOR = light ? fl_rgb_color(212, 232, 216) : fl_rgb_color(43, 64, 51);
        WINDOW_BG = light ? fl_rgb_color(237, 243, 236) : fl_rgb_color(27, 34, 29);
        GAP_COLOR = light ? fl_rgb_color(246, 251, 243) : fl_rgb_color(16, 22, 18);
    } else if (material_accent == 2) { // Ocean
        SELECTION = light ? fl_rgb_color(42, 99, 138) : fl_rgb_color(157, 203, 239);
        BUTTON_COLOR = light ? fl_rgb_color(213, 229, 246) : fl_rgb_color(43, 58, 74);
        WINDOW_BG = light ? fl_rgb_color(237, 241, 247) : fl_rgb_color(27, 32, 39);
        GAP_COLOR = light ? fl_rgb_color(247, 249, 255) : fl_rgb_color(16, 20, 26);
    } else if (material_accent == 3) { // Clay
        SELECTION = light ? fl_rgb_color(145, 76, 51) : fl_rgb_color(255, 181, 156);
        BUTTON_COLOR = light ? fl_rgb_color(255, 219, 206) : fl_rgb_color(79, 53, 44);
        WINDOW_BG = light ? fl_rgb_color(249, 237, 231) : fl_rgb_color(40, 30, 27);
        GAP_COLOR = light ? fl_rgb_color(255, 248, 245) : fl_rgb_color(28, 18, 15);
    }
    GRADIENT_COLOR = WINDOW_BG;

    // Keep the existing theme editor and exported RGB files in sync with the roles.
    Fl::get_color(FONT_COLOR, text_red, text_green, text_blue);
    Fl::get_color(FONT2_COLOR, text2_red, text2_green, text2_blue);
    Fl::get_color(WINDOW_BG, bg_red, bg_green, bg_blue);
    Fl::get_color(SELECTION, bg2_red, bg2_green, bg2_blue);
    Fl::get_color(BUTTON_COLOR, button_red, button_green, button_blue);
    Fl::get_color(BORDER_COLOR, border_red, border_green, border_blue);
    Fl::get_color(GAP_COLOR, gap_red, gap_green, gap_blue);
    Fl::get_color(GRADIENT_COLOR, gradient_red, gradient_green, gradient_blue);
    Fl::scheme("gtk+");
    Fl::background(bg_red, bg_green, bg_blue);
    Fl::background2(button_red, button_green, button_blue);
    Fl::foreground(text_red, text_green, text_blue);
    Fl::set_boxtype(Material_CardBox(), material_card, 4, 4, 8, 8);
    Fl::set_boxtype(Material_ControlBox(), material_control, 4, 2, 8, 4);
    Fl::set_boxtype(FL_UP_BOX, material_control, 2, 2, 4, 4);
    Fl::set_boxtype(FL_DOWN_BOX, material_pressed, 2, 2, 4, 4);
    box_style = Material_CardBox();
    button_style = Material_ControlBox();
    Fl::set_boxtype(static_cast<Fl_Boxtype>(FL_FREE_BOXTYPE + 6),
                    material_pressed, 4, 2, 8, 4);

}
