/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nobody";

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

