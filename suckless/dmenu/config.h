/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {
	"CaskaydiaCove Nerd Font Mono:size=10"
};
static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
static const unsigned int min_lineheight = 27;
static unsigned int lineheight = 27;
static unsigned int fuzzy = 0;

/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 0;

static int dmx = 10; /* put dmenu at this x offset */
static int dmy = 10; /* put dmenu at this y offset (measured from the bottom if topbar is 0) */
static unsigned int dmw = 1900; /* make dmenu this wide */
static char **hpitems = {"firefox-developer-edition", "st"};

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";
