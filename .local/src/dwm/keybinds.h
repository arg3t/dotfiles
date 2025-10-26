/*
 __   _______ _____ _____
 \ \ / / ____| ____|_   _|
  \ V /|  _| |  _|   | |
   | | | |___| |___  | |
   |_| |_____|_____| |_|
  Yeet's DWM keybinds
*/

#include "movestack.c"
#include <X11/XF86keysym.h>

#ifndef keybinds_h
#define keybinds_h

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd)                                                             \
  {                                                                            \
    .v = (const char *[]) { "/bin/sh", "-c", cmd, NULL }                       \
  }

static char dmenumon[2] = "0";
static const char *dmenucmd[] = {USERNAME "/.local/bin/dmenu_run_history", "-m",
                                 dmenumon};
static const char *termcmd[] = {"/usr/local/bin/st", NULL};
static const char *termcmd_alt[] = {"/usr/bin/alacritty", NULL};
static const char *upvol[] = {"ponymix", "-N", "increase", "5", NULL};
static const char *downvol[] = {"ponymix", "-N", "decrease", "5", NULL};
static const char *mutevol[] = {"ponymix", "-N", "toggle", NULL};

static const char *upbright[] = {"/usr/bin/xbacklight", "-inc", "10", NULL};
static const char *downbright[] = {"/usr/bin/xbacklight", "-dec", "10", NULL};

static const char *lock[] = {"/usr/local/bin/slock", NULL};
static const char *clipmenu[] = {"/usr/bin/clipmenu", "-i", NULL};
static const char *play[] = {"/usr/bin/playerctl", "play-pause", NULL};
static const char *prev[] = {"/usr/bin/playerctl", "previous", NULL};
static const char *next[] = {"/usr/bin/playerctl", "next", NULL};
static const char *outmenu[] = {USERNAME "/.local/bin/dmenu-logout", NULL};
static const char *refresh[] = {USERNAME "/.local/bin/dmenu-refresh", NULL};
static const char *keyboard[] = {USERNAME "/.local/bin/kbmap_toggle", NULL};

static const char *screenshot[] = {
    "scrot", "/tmp/%Y-%m-%d-%s_$wx$h.png", "-e",
    "xclip -selection clipboard -target image/png -i $f; cp $f "
    "~/Pictures/Screenshots;notify-send -a \"SNAP\" \"$f\"",
    NULL};
static const char *windowshot[] = {"flameshot", "gui", NULL};
static const char *simcrop[] = {"simcrop", "-fc", "-sc", "-g", "900x500", NULL};

static const char *notification[] = {USERNAME "/.local/bin/dunst_toggle.sh",
                                     "-t", NULL};

static const char *screensaver[] = {USERNAME "/.local/bin/screensaver_toggle",
                                    "-t", NULL};

static const char *toolkit[] = {USERNAME "/.local/bin/dmenu-toolkit", NULL};

static const char *bwmenu[] = {USERNAME "/.local/bin/password_manager", NULL};

static const char *sessionload[] = {USERNAME "/.local/bin/dmenu-sessions",
                                    NULL};

static const char *wallabag[] = {USERNAME "/.local/bin/dmenu-wallabag", "-s",
                                 NULL};
static const char *wiki[] = {USERNAME "/.local/bin/dmenu-arch", NULL};

static const char *grabcolor[] = {USERNAME "/.local/bin/grabcolor", NULL};
static const char *wc[] = {USERNAME "/.local/bin/dmenu-wc", NULL};
static const char *network_manager[] = {USERNAME "/.local/bin/connman_dmenu",
                                        NULL};
static const char *genpwd[] = {USERNAME "/.local/bin/genpwd", NULL};
static const char *web[] = {USERNAME "/.local/bin/dmenu-web", NULL};
static const char *xrandr[] = {USERNAME "/.local/bin/dmenu-xrandr", NULL};
static const char *surf[] = {USERNAME "/.local/bin/tabbed_surf", NULL};
static const char *hamster[] = {USERNAME "/.local/bin/dmenu-hamster", NULL};

/* commands */
static Key keys[] = {
    /* modifier                     key        function        argument */
    {MODKEY, XK_d, spawn, {.v = dmenucmd}},
    {MODKEY, XK_p, spawn, {.v = bwmenu}},
    {MODKEY, XK_Return, spawn, {.v = termcmd}},
    {MODKEY | ShiftMask, XK_Return, spawn, {.v = termcmd_alt}},
    {MODKEY, XK_b, togglebar, {0}},
    {MODKEY, XK_k, focusstack, {.i = -1}},
    {MODKEY, XK_j, focusstack, {.i = +1}},
    {MODKEY, XK_i, focusmaster, {0}},
    {MODKEY | ShiftMask, XK_i, spawn, {.v = screensaver}},
    {MODKEY | ShiftMask, XK_n, spawn, {.v = notification}},
    {MODKEY, XK_l, setmfact, {.f = +0.05}},
    {MODKEY, XK_h, setmfact, {.f = -0.05}},
    {MODKEY | ShiftMask, XK_z, zoom, {0}},
    {MODKEY, XK_Tab, view, {0}},

#if VPS == 1
    {MODKEY | ShiftMask, XK_q, killclient, {0}},
#else
    {MODKEY, XK_q, killclient, {0}},
    {MODKEY | ShiftMask, XK_q, spawn, {.v = outmenu}},
#endif

    {MODKEY | Mod1Mask, XK_i, incnmaster, {.i = +1}},
    {MODKEY | Mod1Mask, XK_s, incnmaster, {.i = -1}},
    {MODKEY | ShiftMask, XK_j, movestack, {.i = +1}},
    {MODKEY | ShiftMask, XK_k, movestack, {.i = -1}},
    {MODKEY | Mod1Mask, XK_t, setlayout, {.v = &layouts[0]}}, /*tiled*/
    {MODKEY | Mod1Mask, XK_f, setlayout, {.v = &layouts[1]}}, /*Spiral*/
    {MODKEY | Mod1Mask, XK_c, setlayout, {.v = &layouts[3]}}, /*center*/
    {MODKEY | Mod1Mask,
     XK_space,
     setlayout,
     {.v = &layouts[4]}}, /*Center floating*/
    {MODKEY | Mod1Mask, XK_m, setlayout, {.v = &layouts[5]}}, /*monocle*/
    {MODKEY | Mod1Mask, XK_d, setlayout, {.v = &layouts[6]}}, /*Deck*/
    {MODKEY | ShiftMask, XK_space, togglefloating, {0}},      /* [>float<] */
    {MODKEY, XK_f, togglefullscr, {0}},                     /*[>Fullscreen<] */
    {MODKEY | Mod1Mask, XK_comma, cyclelayout, {.i = -1}},  /*Ciclar layouts*/
    {MODKEY | Mod1Mask, XK_period, cyclelayout, {.i = +1}}, /*Ciclar layouts*/
    {MODKEY, XK_a, view, {.ui = ~0}},
    {MODKEY | Mod1Mask, XK_a, tag, {.ui = ~0}},
    {MODKEY, XK_comma, focusmon, {.i = -1}},
    {MODKEY, XK_period, focusmon, {.i = +1}},
    {MODKEY | Mod1Mask, XK_g, togglegaps, {0}},
    {MODKEY | ShiftMask, XK_comma, tagmon, {.i = -1}},
    {MODKEY | ShiftMask, XK_period, tagmon, {.i = +1}},
    TAGKEYS(XK_1, 0) TAGKEYS(XK_2, 1) TAGKEYS(XK_3, 2) TAGKEYS(XK_4, 3)
        TAGKEYS(XK_5, 4) TAGKEYS(XK_6, 5) TAGKEYS(XK_7, 6) TAGKEYS(XK_8, 7)
            TAGKEYS(XK_9, 8){MODKEY, XK_x, spawn, {.v = lock}},
    {MODKEY, XK_c, spawn, {.v = clipmenu}},
    {MODKEY | ShiftMask, XK_p, spawn, {.v = genpwd}},
    {MODKEY | Mod1Mask, XK_k, spawn, {.v = keyboard}}, /*tiled*/
    {MODKEY | ShiftMask, XK_r, spawn, {.v = refresh}}, /*tiled*/
    {0, XF86XK_AudioLowerVolume, spawn, {.v = downvol}},
    {0, XF86XK_MonBrightnessUp, spawn, {.v = upbright}},
    {0, XF86XK_MonBrightnessDown, spawn, {.v = downbright}},
    {0, XF86XK_AudioMute, spawn, {.v = mutevol}},
    {0, XF86XK_AudioRaiseVolume, spawn, {.v = upvol}},
    {0, XF86XK_AudioPrev, spawn, {.v = prev}},
    {0, XF86XK_AudioPlay, spawn, {.v = play}},
    {0, XF86XK_AudioNext, spawn, {.v = next}},
    {0, XK_Print, spawn, {.v = screenshot}},
    {MODKEY | ShiftMask | Mod1Mask, XK_s, togglesticky, {0}},
    {MODKEY, XK_Print, spawn, {.v = windowshot}},
    {MODKEY | ShiftMask, XK_s, spawn, {.v = xrandr}},
    {MODKEY | ShiftMask, XK_l, spawn, {.v = sessionload}},
    {MODKEY, XK_u, spawn, {.v = web}},
    {MODKEY | ShiftMask, XK_h, spawn, {.v = hamster}},
    {MODKEY, XK_t, spawn, {.v = toolkit}},
    {MODKEY, XK_s, togglescratch, {.ui = 0}},
    {MODKEY | ShiftMask, XK_f, togglescratch, {.ui = 2}},
    {MODKEY | ShiftMask, XK_c, togglescratch, {.ui = 3}},
    /* FloatPos Patch Keybinds */
    {Mod3Mask, XK_u, floatpos, {.v = "-26x -26y"}},      // ↖
    {Mod3Mask, XK_i, floatpos, {.v = "  0x -26y"}},      // ↑
    {Mod3Mask, XK_o, floatpos, {.v = " 26x -26y"}},      // ↗
    {Mod3Mask, XK_j, floatpos, {.v = "-26x   0y"}},      // ←
    {Mod3Mask, XK_l, floatpos, {.v = " 26x   0y"}},      // →
    {Mod3Mask, XK_m, floatpos, {.v = "-26x  26y"}},      // ↙
    {Mod3Mask, XK_comma, floatpos, {.v = "  0x  26y"}},  // ↓
    {Mod3Mask, XK_period, floatpos, {.v = " 26x  26y"}}, // ↘
    /* Resize client, client center position is fixed which means that client
       expands in all directions */
    {Mod3Mask | ShiftMask, XK_u, floatpos, {.v = "-26w -26h"}},      // ↖
    {Mod3Mask | ShiftMask, XK_i, floatpos, {.v = "  0w -26h"}},      // ↑
    {Mod3Mask | ShiftMask, XK_o, floatpos, {.v = " 26w -26h"}},      // ↗
    {Mod3Mask | ShiftMask, XK_j, floatpos, {.v = "-26w   0h"}},      // ←
    {Mod3Mask | ShiftMask, XK_k, floatpos, {.v = "800W 800H"}},      // ·
    {Mod3Mask | ShiftMask, XK_l, floatpos, {.v = " 26w   0h"}},      // →
    {Mod3Mask | ShiftMask, XK_m, floatpos, {.v = "-26w  26h"}},      // ↙
    {Mod3Mask | ShiftMask, XK_comma, floatpos, {.v = "  0w  26h"}},  // ↓
    {Mod3Mask | ShiftMask, XK_period, floatpos, {.v = " 26w  26h"}}, // ↘
};

#endif /* keybinds_h */
