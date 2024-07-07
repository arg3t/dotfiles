/*
 __   _______ _____ _____
 \ \ / / ____| ____|_   _|
  \ V /|  _| |  _|   | |
   | | | |___| |___  | |
   |_| |_____|_____| |_|
  Yeet's DWM configuration
*/

typedef struct {
	const char *name;
	const void *cmd;
} Sp;

#define STATUSBAR "dwmblocks"
static const char *layoutmenu_cmd = USERNAME"/.local/bin/layoutmenu.sh";
unsigned const int swallowfloating = 0;

/* tagging */
static const char *tags[9] = {"", "", "", "", "", "", "", "", ""};
static const char *busytags[9] = {"", "", "", "", "", "", "", "", ""};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */

#define FORCE_VSPLIT 1  /* nrowgrid layout: force two clients to always split vertically */
#define PERTAG_PATCH 1
#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[T]",      tile },    /* first entry is default */
 	{ "[F]",      dwindle },
	{ "[F]",      grid },
	{ "[C]",      centeredmaster },
	{ "[c]",      centeredfloatingmaster },
	{ "[M]",      monocle },
	{ "[D]",      deck },
	{ NULL,       NULL },
};

/* scratchpads */
const char *spcmd1[] = {"st", "-c", "scratchpad", "-n", "spterm", "-g", "120x34", NULL };
static const char *spcmd3[]  = { "/usr/bin/nemo", "-g", "1200x700", "--class=spfile", "--name=spfile", NULL };
static const char *spcmd4[]  = { "/usr/local/bin/st", "-g", "150x35", "-c", "spcal", "-n", "spcal", "-e", "qcal", NULL };
static const char *spcmd5[]  = { USERNAME"/.local/bin/noteapp" };

static Sp scratchpads[] = {
   {"spterm",      spcmd1},
   {"spfile",      spcmd3},
   {"spcal",      spcmd4},
   {"obsidian",      spcmd5},
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },


static const char *mouse_dmenu[] = {"/home/yigit/.local/bin/mousemenu", NULL};
/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkRootWin,           0,              Button3,        spawn,          {.v = mouse_dmenu} },
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
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
};

static Signal signals[] = {
	/* signum           function */
	{ "focusstack",     focusstack },
};
