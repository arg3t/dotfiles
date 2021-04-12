/* See LICENSE file for copyright and license details. */

typedef struct {
	const char *name;
	const void *cmd;
} Sp;

#define STATUSBAR "dwmblocks"
static const char *layoutmenu_cmd = "layoutmenu.sh";
static const int swallowfloating =  0;

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */

#define FORCE_VSPLIT 1  /* nrowgrid layout: force two clients to always split vertically */
#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "鉶",      tile },    /* first entry is default */
 	{ "",      dwindle },
	{ "ﱖ",      grid },
	{ "",      centeredmaster },
	{ "",      centeredfloatingmaster },
	{ "[M]",      monocle },
	{ "[D]",      deck },
	{ NULL,       NULL },
};

/* scratchpads */
const char *spcmd1[] = {"st", "-c", "scratchpad", "-n", "spterm", "-g", "120x34", NULL };
const char *spcmd2[] = {"feh", "--title", "scratchpad", "--class", "spfeh", "-g","900x300+500+350", "/home/yigit/Pictures/us_keyboard.png", NULL};
const char *spcmd3[] = {"st", "-c", "scratchpad", "-n", "spmutt", "-g", "180x51", "-e", "neomutt", NULL };
static const char *spcmd4[]  = { "/usr/local/bin/st", "-g", "150x35", "-c", "spfile", "-n", "spfile", "-e", "/home/yigit/.local/bin/lf-ueberzug", NULL };
static const char *spcmd5[]  = { "/usr/local/bin/st", "-g", "150x35", "-c", "spmusic", "-n", "spmusic", "-e", "ncmpcpp", NULL };
static const char *spcmd6[]  = { "/usr/local/bin/st", "-g", "150x35", "-c", "spcal", "-n", "spcal", "-e", "calcurse", NULL };

static Sp scratchpads[] = {
   {"spterm",      spcmd1},
   {"spfeh",       spcmd2},
   {"spmutt",      spcmd3},
   {"spfile",      spcmd4},
   {"spmusic",      spcmd5},
   {"spcal",      spcmd6},
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        layoutmenu,     {0} },
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
};

