#include <X11/XF86keysym.h>

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

static char dmenumon[2] = "0"; 
static const char *dmenucmd[] = { "/home/yigit/.scripts/dmenu_run_history", "-m", dmenumon, "-z", "1900", "-x", "10", "-y", "10"};
static const char *termcmd[]  = { "/usr/local/bin/st","-e", "/home/yigit/.scripts/st_tmux", NULL };
static const char *upvol[]   = { "/home/yigit/.scripts/pacontrol.sh", "up",     NULL };
static const char *downvol[]   = { "/home/yigit/.scripts/pacontrol.sh", "down",     NULL };
static const char *mutevol[]   = { "/home/yigit/.scripts/pacontrol.sh", "toggle-mute",     NULL };

static const char *upbright[] = {"/usr/bin/xbacklight","-inc","10",NULL};
static const char *downbright[] = {"/usr/bin/xbacklight","-dec","10",NULL};

static const char *lock[] = {"/home/yigit/.scripts/lock",NULL};
static const char *clipmenu[] = {"/usr/bin/clipmenu","-i",NULL};
static const char *play[] = {"/usr/bin/playerctl","play-pause",NULL};
static const char *prev[] = {"/usr/bin/playerctl","previous",NULL};
static const char *next[] = {"/usr/bin/playerctl","next",NULL};
static const char *outmenu[] = {"/home/yigit/.scripts/dmenu-logout", NULL};
static const char *refresh[] = {"/home/yigit/.scripts/dmenu-refresh", NULL};
static const char *keyboard[] = {"/home/yigit/.scripts/kbmap_toggle", NULL};

static const char *screenshot[] = { "scrot", "/tmp/%Y-%m-%d-%s_$wx$h.png", "-e","xclip -selection clipboard -target image/png -i $f; cp $f ~/Pictures/Screenshots;notify-send \"SNAP\" \"$f\"", NULL }; 
static const char *windowshot[] = { "scrot", "-u", "/tmp/%Y-%m-%d-%s_$wx$h.png", "-e","xclip -selection clipboard -target image/png -i $f; cp $f ~/Pictures/Screenshots;notify-send \"SNAP\" \"$f\"", NULL };
static const char *simcrop[] = {"simcrop","-fc","-sc", "-g", "900x500",NULL};

static const char *notification_off[] = {"/home/yigit/.scripts/dunst_toggle.sh","-s",NULL};
static const char *notification_on[] = {"/home/yigit/.scripts/dunst_toggle.sh", "-e",NULL};

static const char *screensaver_off[] = {"/home/yigit/.scripts/screensaver_toggle","-s",NULL};
static const char *screensaver_on[] = {"/home/yigit/.scripts/screensaver_toggle", "-e",NULL};

static const char *online_class[] = {"/home/yigit/.scripts/tedportal",NULL};

static const char *bwmenu[] = {"/home/yigit/.scripts/password_manager", NULL};


static const char *network_manager[] = {"/home/yigit/.scripts/networkmanager_dmenu"};
static const char *mconnect[] = {"/home/yigit/.scripts/dmenu-mconnect"};
static const char *genpwd[] = {"sh", "-c","/sbin/bw generate | xclip" };
static const char *trackpad[] = {"/home/yigit/.scripts/toggle_touchpad.sh"};
static const char *bluetooth[] = {"/home/yigit/.scripts/dmenu-bluetooth", NULL};
static const char *url[] = {"/home/yigit/.scripts/dmenu_surf", NULL};
static const char *surf[] = {"/home/yigit/.scripts/tabbed_surf", NULL};
static const char *google[] = {"/home/yigit/.scripts/menu-surfraw", "google", NULL};
static const char *youtube[] = {"/home/yigit/.scripts/ytfzf_dmenu", NULL};

/* commands */
static Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_d,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_p,      spawn,          {.v = bwmenu } },
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_i,      spawn,          {.v = screensaver_off} },
	{ MODKEY|ShiftMask,             XK_i,      spawn,          {.v = screensaver_on } },
	{ MODKEY,                       XK_n,      spawn,          {.v = notification_off} },
	{ MODKEY|ShiftMask,             XK_n,      spawn,          {.v = notification_on } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY,                       XK_q,      killclient,     {0} },
	{ MODKEY|Mod1Mask,              XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY|Mod1Mask,              XK_s,      incnmaster,     {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_j,      movestack,      {.i = +1 } }, 
	{ MODKEY|ShiftMask,             XK_k,      movestack,      {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_t,      setlayout,      {.v = &layouts[0]} }, /*tiled*/
	{ MODKEY|Mod1Mask,              XK_f,      setlayout,      {.v = &layouts[1]} }, /*Spiral*/
	{ MODKEY|Mod1Mask,              XK_g,      setlayout,      {.v = &layouts[2]} }, /*Grid*/
	{ MODKEY|Mod1Mask,              XK_c,      setlayout,      {.v = &layouts[3]} }, /*center*/
	{ MODKEY|Mod1Mask,              XK_space,  setlayout,      {.v = &layouts[4]} }, /*Center floating*/
	{ MODKEY|Mod1Mask,              XK_m,      setlayout,      {.v = &layouts[5]} }, /*monocle*/
	{ MODKEY|Mod1Mask,             	XK_d,      setlayout,      {.v = &layouts[6]} }, /*Deck*/
	{ MODKEY|ShiftMask,            	XK_space,  togglefloating, {0} }, /* [>float<] */
	{ MODKEY,			            			XK_f,    	 togglefullscreen,  {0} }, /*[>Fullscreen<] */
	{ MODKEY|Mod1Mask,              XK_comma,  cyclelayout,    {.i = -1 } }, /*Ciclar layouts*/
	{ MODKEY|Mod1Mask,              XK_period, cyclelayout,    {.i = +1 } }, /*Ciclar layouts*/
	{ MODKEY,                       XK_a,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_a,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } }, 
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q, 			spawn, {.v = outmenu} },
	{ MODKEY|ShiftMask,             XK_t, 			spawn, {.v = trackpad} },
	{ MODKEY,                       XK_x, 			spawn, {.v = lock } },
	{ MODKEY,                       XK_c, 			spawn, {.v = clipmenu } },
	{ MODKEY|ShiftMask,             XK_p,			  spawn, {.v = genpwd} },
	{ MODKEY|ShiftMask,             XK_b,			  spawn, {.v = bluetooth } },
	{ MODKEY|Mod1Mask,              XK_n, 			spawn, {.v = network_manager} }, /*Spiral*/
	{ MODKEY|Mod1Mask,              XK_k,       spawn,      {.v = keyboard} }, /*tiled*/
	{ MODKEY|ShiftMask,              XK_r,       spawn,      {.v = refresh} }, /*tiled*/
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
	{ MODKEY|ShiftMask, 						XK_e, spawn, {.v = simcrop } },
	{ MODKEY,                       XK_u, spawn, {.v = url} },
	{ MODKEY,                       XK_g, spawn, {.v = google} },
	{ MODKEY|ShiftMask,							XK_c, spawn, {.v = online_class} },
	{ MODKEY|ShiftMask,							XK_m, spawn, {.v = mconnect} },
	{ MODKEY,                       XK_y, spawn, {.v = youtube} },
	{ MODKEY,                       XK_s,      togglescratch,          {.ui = 0 } },
	{ MODKEY|ShiftMask,                       XK_s,      togglescratch,          {.ui = 1 } },
	{ MODKEY,                       XK_m,      togglescratch,          {.ui = 2 } },
	/* FloatPos Patch Keybinds */
	{ Mod3Mask,                     XK_u,            floatpos,               {.v = "-26x -26y" } }, // ↖
	{ Mod3Mask,                     XK_i,            floatpos,               {.v = "  0x -26y" } }, // ↑
	{ Mod3Mask,                     XK_o,            floatpos,               {.v = " 26x -26y" } }, // ↗
	{ Mod3Mask,                     XK_j,            floatpos,               {.v = "-26x   0y" } }, // ←
	{ Mod3Mask,                     XK_l,            floatpos,               {.v = " 26x   0y" } }, // →
	{ Mod3Mask,                     XK_m,            floatpos,               {.v = "-26x  26y" } }, // ↙
	{ Mod3Mask,                     XK_comma,        floatpos,               {.v = "  0x  26y" } }, // ↓
	{ Mod3Mask,                     XK_period,       floatpos,               {.v = " 26x  26y" } }, // ↘
	/* Resize client, client center position is fixed which means that client expands in all directions */
	{ Mod3Mask|ShiftMask,           XK_u,            floatpos,               {.v = "-26w -26h" } }, // ↖
	{ Mod3Mask|ShiftMask,           XK_i,            floatpos,               {.v = "  0w -26h" } }, // ↑
	{ Mod3Mask|ShiftMask,           XK_o,            floatpos,               {.v = " 26w -26h" } }, // ↗
	{ Mod3Mask|ShiftMask,           XK_j,            floatpos,               {.v = "-26w   0h" } }, // ←
	{ Mod3Mask|ShiftMask,           XK_k,            floatpos,               {.v = "800W 800H" } }, // ·
	{ Mod3Mask|ShiftMask,           XK_l,            floatpos,               {.v = " 26w   0h" } }, // →
	{ Mod3Mask|ShiftMask,           XK_m,            floatpos,               {.v = "-26w  26h" } }, // ↙
	{ Mod3Mask|ShiftMask,           XK_comma,        floatpos,               {.v = "  0w  26h" } }, // ↓
	{ Mod3Mask|ShiftMask,           XK_period,       floatpos,               {.v = " 26w  26h" } }, // ↘
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */

static Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkStatusText,        0,                   Button1,        sigdwmblocks,   {.i = 1 } },
	{ ClkStatusText,        0,                   Button2,        sigdwmblocks,   {.i = 2 } },
	{ ClkStatusText,        0,                   Button3,        sigdwmblocks,   {.i = 3 } },
	{ ClkLtSymbol,          0,                   Button3,        layoutmenu,     {0} },
};

