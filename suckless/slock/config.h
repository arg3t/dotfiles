/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nobody";


static const char *lights_on[]  = { "/bin/curl", "http://yeetclock/setcolor?R=136&G=192&B=208&O=1", NULL };
static const char *lights_off[]  = { "/bin/curl", "http://yeetclock/setcolor?R=0&G=0&B=0&O=0", NULL };
static const char *notifications_on[]  = { "/home/yigit/.local/bin/dunst_toggle.sh", "-e", NULL };
static const char *notifications_off[]  = { "/home/yigit/.local/bin/dunst_toggle.sh", "-s", NULL };
static const char *mute_on[]  = { "/home/yigit/.local/bin/pacontrol.sh", "open-mute", NULL };
static const char *mute_off[]  = { "/home/yigit/.local/bin/pacontrol.sh", "close-mute", NULL };
static const char *screensaver_off[]  = { "/home/yigit/.local/bin/screensaver_toggle", "-s", NULL };
static const char *screensaver_on[]  = { "/home/yigit/.local/bin/screensaver_toggle", "-e", NULL };

static const char **prelock[] = {lights_off, notifications_off, mute_on, screensaver_off};
static const char **postlock[] = {lights_on, notifications_on, mute_off, screensaver_on};

static const char *colorname[NUMCOLS] = {
	[INIT] =   "black",     /* after initialization */
	[INPUT] =  "#3a575c",   /* during input */
	[FAILED] = "#bf616a",   /* wrong password */
	[CAPS] = "#ebcb8b",         /* CapsLock on */
};

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 0;

/* default message */
static const char * message = "\
            .-""-.\n\
           / .--. \\\n\
          / /    \\ \\\n\
          | |    | |\n\
          | |.-""-.|\n\
         ///`.::::.`\\\n\
        ||| ::/  \\:: ;\n\
        ||; ::\\__/:: ;\n\
         \\\\\\ '::::' /\n\
          `=':-..-'`\n\
";

/* text color */
static const char * text_color = "#ffffff";

/* text size (must be a valid size) */
static const char * font_name = "fixed";

