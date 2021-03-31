/* See LICENSE file for copyright and license details. */

#include <X11/XF86keysym.h>
/* appearance */
static const int rmaster                 = 0;        /* 1 = master at right*/
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static int showsystray        					 = 1;     /* 0 means no systray */
static const int tag_padding        		 = 0;
static const char *layoutmenu_cmd        = "/home/yigit/.local/share/bin/layoutmenu.sh";
static const char autostartblocksh[]     = "autostart_blocking.sh";
static const char autostartsh[]          = "autostart.sh";
static const char dwmdir[]               = "dwm";
static const char localshare[]           = ".config/suckless";

static int floatposgrid_x                = 5;  /* float grid columns */
static int floatposgrid_y                = 5;  /* float grid rows */

/* systray */
static int tagindicatortype              = INDICATOR_TOP_LEFT_SQUARE;
static int tiledindicatortype            = INDICATOR_NONE;
static int floatindicatortype            = INDICATOR_TOP_LEFT_SQUARE;

/* vanity gaps */
static const unsigned int gappih         = 20;  /* horiz inner gap between windows */
static const unsigned int gappiv         = 10;  /* vert inner gap between windows */
static const unsigned int gappoh         = 10;  /* horiz outer gap between windows and screen edge */
static const unsigned int gappov         = 30;  /* vert outer gap between windows and screen edge */
static const int smartgaps               = 0;   /* 1 means no outer gap when there is only one window */

/* tagging */
static char *tagicons[][NUMTAGS] = {
	[DEFAULT_TAGS]        = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
	[ALTERNATIVE_TAGS]    = { "A", "B", "C", "D", "E", "F", "G", "H", "I" },
};

/* layout(s) */
static const float mfact     = 0.5; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "鉶",      tile },    /* first entry is default */
 	{ "",      dwindle },
	{ "ﱖ",      grid },
	{ "",      centeredmaster },
	{ "",      centeredfloatingmaster },
	{ "[M]",      monocle },
	{ "[D]",      deck },
};


const char *spcmd1[] = {"st", "-c", "scratchpad", "-n", "spterm", "-g", "120x34", NULL };
const char *spcmd2[] = {"feh", "--title", "scratchpad", "--class", "spfeh", "-g","900x300+500+350", "/home/yigit/Pictures/us_keyboard.png", NULL};
const char *spcmd3[] = {"st", "-c", "scratchpad", "-n", "spmutt", "-g", "180x51", "-e", "neomutt", NULL };
static const char *spcmd4[]  = { "/usr/local/bin/st", "-g", "150x35", "-c", "spfile", "-n", "spfile", "-e", "/home/yigit/.local/share/bin/lf-ueberzug", NULL };
static const char *spcmd5[]  = { "/usr/local/bin/st", "-g", "150x35", "-c", "spmusic", "-n", "spmusic", "-e", "ncmpcpp", NULL };

static Sp scratchpads[] = {
   {"spterm",      spcmd1},
   {"spfeh",       spcmd2},
   {"spmutt",      spcmd3},
   {"spfile",      spcmd4},
   {"spmusic",      spcmd5},
};

static const BarRule barrules[] = {
	/* monitor  bar    alignment         widthfunc                drawfunc                clickfunc                name */
	{ -1,       0,     BAR_ALIGN_LEFT,   width_tags,              draw_tags,              click_tags,              "tags" },
	//{  0,       0,     BAR_ALIGN_RIGHT,  width_systray,           draw_systray,           click_systray,           "systray" },
	{ -1,       0,     BAR_ALIGN_LEFT,   width_ltsymbol,          draw_ltsymbol,          click_ltsymbol,          "layout" },
	{ 'A',      0,     BAR_ALIGN_RIGHT,  width_status2d,          draw_status2d,          click_statuscmd,         "status2d" },
};


