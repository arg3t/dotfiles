/* appearance */
static const unsigned int gappx     = 6;
static const unsigned int borderpx  = 3;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int user_bh            = 27;
static const int bar_height = 27;
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "CaskaydiaCove Nerd Font:size=10" };
static const char dmenufont[]       = "CaskaydiaCove Nerd Font:size=10";

static const int vertpad                 = 10;  /* vertical padding of bar */
static const int sidepad                 = 10;  /* horizontal padding of bar */

static const char fore[]   = "#e5e9f0";
static const char back[]   = "#0f111a";
static const char border[] = "#3a575c";
static const char col0[]   = "#3b4252";
static const char col1[]   = "#bf616a"; /* red */
static const char col2[]   = "#a3be8c"; /* green */
static const char col3[]   = "#ebcb8b"; /* yellow */
static const char col4[]   = "#81a1c1"; /* light_blue */
static const char col5[]   = "#a48ead"; /* puple */
static const char col6[]   = "#88c0d0"; /* blue */
static const char col7[]   = "#e5e9f0"; /* white */
static const char col8[]   = "#4c566a"; /* gray */

static char *colors[][ColCount] = {
	/*                       fg                bg                border                float */
	[SchemeNorm]         = { fore, back, border, border},
	[SchemeSel]          = { fore, back, col1, border},
	[SchemeTitleNorm]    = { fore, back, border },
	[SchemeTitleSel]     = { fore, back, border, border},
	[SchemeTagsNorm]     = { fore, back, border, border},
	[SchemeTagsSel]      = { back, col1, border, border},
	[SchemeHid]          = { back, col4, border, border},
	[SchemeUrg]          = { back, col5, border, border},
};

