/* See LICENSE file for copyright and license details. */

#include <X11/XF86keysym.h>
/* appearance */
static const unsigned int borderpx  = 3;        /* border pixel of windows */
static const unsigned int gappx     = 6;
static const unsigned int snap      = 32;       /* snap pixel */
static const int rmaster            = 0;        /* 1 = master at right*/
static const int showbar            = 1;        /* 0 means no bar */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;     /* 0 means no systray */
static const int topbar             = 1;        /* 0 means bottom bar */
static const int user_bh            = 27;        /* 0 means that dwm will calculate bar height, >= 1 means dwm will user_bh as bar height */
static const int tag_padding        = 0;        
static const int vertpad            = 0;       /* vertical padding of bar */
static const int sidepad            = 0;       /* horizontal padding of bar */
static const char *fonts[]          = {"Hack Nerd Font:Regular:size=10", "Material Design Icons:Regular:pixelsize=16:antialias=true"};
static const char dmenufont[]       = "Hack Nerd Font:size=10";
static const char fore[]   = "#f8f8f2";
static const char back[]   = "#282a36"; 
static const char border[] = "#f8f8f2";
static const char col0[]   = "#000000";
static const char col1[]   = "#FF5555";
static const char col2[]   = "#50FA7B";
static const char col3[]   = "#F1FA8C";
static const char col4[]   = "#BD93F9";
static const char col5[]   = "#FF79C6";
static const char col6[]   = "#8BE9FD";
static const char col7[]   = "#BFBFBF";
static const char col8[]   = "#4D4D4D";
static const char col9[]   = "#FF6E67";
static const char col10[]  = "#5AF78E";
static const char col11[]  = "#F4F99D";
static const char col12[]  = "#CAA9FA";
static const char col13[]  = "#FF92D0";
static const char col14[]  = "#9AEDFE";
static const char col15[]  = "#E6E6E6";

static const char spotify[]= "#1FC167";
 

static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm]     = { fore,      back,      back   }, // \x0b
	[SchemeSel]      = { fore,      back,      border }, // \x0c
	[SchemeStatus]   = { fore,      back,      border }, // \x0d  Statusbar right 
	[SchemeTagsSel]  = { col4,      back,      border }, // \x0e  Tagbar left selected 
    [SchemeTagsNorm] = { fore,      back,      border }, // \x0f  Tagbar left unselected 
    [SchemeInfoSel]  = { fore,      back,      border }, // \x10  infobar middle  selected 
    [SchemeInfoNorm] = { fore,      back,      border }, // \x11  infobar middle  unselected 
	[SchemeCol1]     = { col1,      back,      col0   }, // \x12 
	[SchemeCol2]     = { col2,      back,      col0   }, // \x13
	[SchemeCol3]     = { col3,      back,      col0   }, // \x14 
	[SchemeCol4]     = { col4,      back,      col0   }, // \x15
	[SchemeCol5]     = { col5,      back,      col0   }, // \x16 
	[SchemeCol6]     = { col6,      back,      col0   }, // \x17
	[SchemeCol7]     = { col7,      back,      col0   }, // \x18
	[SchemeCol8]     = { col8,      back,      col0   }, // \x19
	[SchemeCol9]     = { col9,      back,      col0   }, // \x1a
	[SchemeCol10]    = { col10,     back,      col0   }, // \x1b
	[SchemeCol11]    = { col11,     back,      col0   }, // \x1c 
	[SchemeCol12]    = { spotify,   back,      col0   }, // \x1d Spotify
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"};
//static const char *alttags[] = { "󰄯", "󰄯", "󰄯", "󰄯"};
 
static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class                         instance    title       tags mask     isfloating   monitor */
	{ "discord",                        NULL,       NULL,       1 << 8,            0,           -1 },
	{ "Mailspring",                        NULL,       NULL,       1 << 7,            0,           -1 },
	{ "Thunderbird",                        NULL,       NULL,       1 << 7,            0,           -1 },
	{ "Termite",                        NULL,       NULL,       1 << 0,            0,           -1 },
	{ "firefoxdeveloperedition",        NULL,       NULL,       1 << 1,            0,           -1 },
	{ "Tor Browser",                    NULL,       NULL,       1 << 1,            0,           -1 },
	{ "Chromium",                       NULL,       NULL,       1 << 1,            0,           -1 },
//	{ "zoom",                           NULL,       NULL,       1 << 4,            0,           -1 },
	{ "TelegramDesktop",                NULL,       NULL,       1 << 8,            0,           -1 },
	{ "whatsapp-nativefier-d52542",     NULL,       NULL,       1 << 8,            0,           -1 },
	{ "neomutt",                        NULL,       NULL,       1 << 7,            0,           -1 },
	{ "Sublime_Text",                   NULL,       NULL,       1 << 2,            0,           -1 },
	{ "code-oss",                       NULL,       NULL,       1 << 2,            0,           -1 },
	{ "jetbrains-idea",                 NULL,       NULL,       1 << 2,            0,           -1 },
	{ "Nemo",                           NULL,       NULL,       1 << 3,            0,           -1 },
	{ "Spotify",                        NULL,       NULL,       1 << 9,            0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.5; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */

#include "fibonacci.c"
#include "layouts.c"
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "鉶",      tile },    /* first entry is default */
 	{ "",      dwindle },
	{ "ﱖ",      grid },
	{ "",      centeredmaster },
	{ "",      centeredfloatingmaster },
	{ "[M]",      monocle },
	{ "[D]",      deck },
	{ NULL, NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|Mod1Mask,		KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggletag,      {.ui = 1 << TAG} },

/* COSAS QUE TENGO QUE AVERIGUAR COMO QUITAR */

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "/usr/bin/rofi","-show","drun", NULL };
static const char *termcmd[]  = { "/usr/bin/termite", "--title", "Terminal", NULL };
static const char *upvol[]   = { "/usr/bin/pactl", "set-sink-volume", "0", "+5%",     NULL };
static const char *downvol[] = { "/usr/bin/pactl", "set-sink-volume", "0", "-5%",     NULL };
static const char *mutevol[] = { "/usr/bin/pactl", "set-sink-mute",   "0", "toggle",  NULL };

static const char *upbright[] = {"/usr/bin/xbacklight","-inc","10",NULL};
static const char *downbright[] = {"/usr/bin/xbacklight","-dec","10",NULL};

static const char *lock[] = {"/usr/bin/betterlockscreen","-l","-t","Stay the fuck out!",NULL};
static const char *clipmenu[] = {"/usr/bin/clipmenu","-i",NULL};
static const char *play[] = {"/usr/bin/playerctl","play-pause",NULL};
static const char *prev[] = {"/usr/bin/playerctl","previous",NULL};
static const char *next[] = {"/usr/bin/playerctl","next",NULL};
static const char *outmenu[] = {"/home/yigit/.scripts/dmenu-logout"};

static const char *notification_off[] = {"/home/yigit/.scripts/dunst_toggle.sh","-s",NULL};
static const char *notification_on[] = {"/home/yigit/.scripts/dunst_toggle.sh", "-e",NULL};

static const char *bwmenu[] = {"/usr/bin/bwmenu", "--auto-lock", "-1", NULL};

static const char *trackpad[] = {"/home/yigit/.scripts/toggle_touchpad.sh"};

static const char *kdeconnect[] = {"/home/yigit/.local/bin/dmenu_kdeconnect.sh", NULL};

static const char *bluetooth[] = {"/usr/bin/rofi-bluetooth", NULL};

static const char *screenshot[] = { "scrot","-d","3", "%Y-%m-%d-%s_$wx$h.jpg", "-e","xclip -selection clipboard -t image/jpg < $f; mv $f ~/Pictures/Screenshots/;dunstify --icon='/home/yigit/.icons/Numix-Circle/48/apps/camera.svg' -a 'SNAP' 'Screenshot taken'", NULL };
static const char *windowshot[] = { "scrot", "-u", "-d","3", "%Y-%m-%d-%s_$wx$h.jpg", "-e","xclip -selection clipboard -t image/jpg < $f; mv $f ~/Pictures/Screenshots/;dunstify --icon='/home/yigit/.icons/Numix-Circle/48/apps/camera.svg' -a 'SNAP' 'Screenshot taken'", NULL };

/* commands */
#include "movestack.c"
#include "shiftview.c"
static Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_d,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_p,      spawn,          {.v = bwmenu } },
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_n,      spawn,          {.v = notification_off} },
	{ MODKEY|ShiftMask,             XK_n,      spawn,          {.v = notification_on } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_s,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY,                       XK_q,      killclient,     {0} },
	{ MODKEY|ShiftMask,             XK_j,      movestack,      {.i = +1 } }, /*Mover ventana hacia abajo*/
    { MODKEY|ShiftMask,             XK_k,      movestack,      {.i = -1 } }, /*Mover ventana hacia arriba*/
    { MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} }, /*tiled*/
    { MODKEY|Mod1Mask,              XK_f,      setlayout,      {.v = &layouts[1]} }, /*Spiral*/
    { MODKEY|Mod1Mask,              XK_g,      setlayout,      {.v = &layouts[2]} }, /*Grid*/
    { MODKEY|Mod1Mask,              XK_c,      setlayout,      {.v = &layouts[3]} }, /*center*/
    { MODKEY,                       XK_m,      setlayout,      {.v = &layouts[5]} }, /*monocle*/
    { MODKEY|ShiftMask,             XK_m,      setlayout,      {.v = &layouts[6]} }, /*Deck*/
    { MODKEY,                       XK_s,      togglefloating, {0} }, /*float*/
    { MODKEY,			            XK_f,    togglefullscr,  {0} }, /*Fullscreen*/
    { MODKEY|Mod1Mask,              XK_comma,  cyclelayout,    {.i = -1 } }, /*Ciclar layouts*/
    { MODKEY|Mod1Mask,              XK_period, cyclelayout,    {.i = +1 } }, /*Ciclar layouts*/
	{ MODKEY,                       XK_a,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_a,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
    /*Monitores*/
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } }, /*Mandar ventana a monitor anterior*/
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } }, /*Mandar ventana a monitor siguiente*/
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	TAGKEYS(                        XK_0,                      9)
	{ MODKEY|ShiftMask,             XK_q, spawn, {.v = outmenu} },
	{ MODKEY|ShiftMask,             XK_t, spawn, {.v = trackpad} },
	{ MODKEY,                       XK_x, spawn, {.v = lock } },
	{ MODKEY,                       XK_c, spawn, {.v = clipmenu } },
	{ MODKEY|ShiftMask,             XK_p, spawn, {.v = kdeconnect } },
	{ MODKEY|ShiftMask,             XK_b, spawn, {.v = bluetooth } },
	{ 0,                            XF86XK_AudioLowerVolume, spawn, {.v = downvol } },
	{ 0,                            XF86XK_MonBrightnessUp, spawn, {.v = upbright } },
	{ 0,                            XF86XK_MonBrightnessDown, spawn, {.v = downbright } },
	{ 0,                            XF86XK_AudioMute, spawn, {.v = mutevol } },
	{ 0,                            XF86XK_AudioRaiseVolume, spawn, {.v = upvol   } },
	{ 0,                            XF86XK_AudioPrev, spawn, {.v = prev  } },
	{ 0,                            XF86XK_AudioPlay, spawn, {.v = play  } },
	{ 0,                            XF86XK_AudioNext, spawn, {.v = next  } },
	{ 0,                            XK_Print, spawn, {.v = screenshot  } },
	{ MODKEY,                       XK_Print, spawn, {.v = windowshot  } },

};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */

static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

/*
static Button buttons[] = {
	// click                event mask      button          function        argument 
	{ ClkLtSymbol,          0,              Button1,        cyclelayout,      {.i = +1 } },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[5]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button1,        sigdwmblocks,   {.i = 1} },
	{ ClkStatusText,        0,              Button2,        sigdwmblocks,   {.i = 2} },
	{ ClkStatusText,        0,              Button3,        sigdwmblocks,   {.i = 3} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkClientWin,		0,		Button1,	winview,	{0} },
};
*/
