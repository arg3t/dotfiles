/**
 * dwmconfig.h 
 * Hardware multimedia keys
 */
/* Somewhere at the beginning of config.h include:

#include <X11/XF86keysym.h>

/* Add somewhere in your constants definition section */

static const char *upvol[]   = { "/usr/bin/pactl", "set-sink-volume", "0", "+5%",     NULL };
static const char *downvol[] = { "/usr/bin/pactl", "set-sink-volume", "0", "-5%",     NULL };
static const char *mutevol[] = { "/usr/bin/pactl", "set-sink-mute",   "0", "toggle",  NULL };

/* Add to keys[] array. With 0 as modifier, you are able to use the keys directly. */
static Key keys[] = {
	{ 0,                       XF86XK_AudioLowerVolume, spawn, {.v = downvol } },
	{ 0,                       XF86XK_AudioMute, spawn, {.v = mutevol } },
	{ 0,                       XF86XK_AudioRaiseVolume, spawn, {.v = upvol   } },
};

/* If you have a small laptop keyboard or don't want to spring your fingers too far away. */

static Key keys[] = {
	{ MODKEY,                       XK_F11, spawn, {.v = downvol } },
	{ MODKEY,                       XK_F9,  spawn, {.v = mutevol } },
	{ MODKEY,                       XK_F12, spawn, {.v = upvol   } },
};
