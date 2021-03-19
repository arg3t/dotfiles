
#define PATH(name)			"/home/yigit/.scripts/status-bar/"name

static Block blocks[] = {
	{ "", PATH("screensaver"),		120,		19},
	{ "", PATH("dunst"),				  120,		18},
	{ "", PATH("mail"),					  120,		23},
	{ "", PATH("keyboard"),			  120,		24},
	{ "", PATH("mconnect"),			  120,		20},
	{ "", PATH("cpu-temp"),				30,			17},
	{ "", PATH("memory"),		  		120,		21},
	{ "", PATH("weather"),				60,			16},
	{ "", PATH("arch"),						120,		15},
	{ "", PATH("volume"),					5,		  14},
	{ "", PATH("network"),				120,		13},
	{ "", PATH("battery"),				60,			12},
	{ "", PATH("time"),					 	30,			11},
	{ "", PATH("date"),					 	240,		22},
};

//Sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char *delim = " | ";

// Have dwmblocks automatically recompile and run when you edit this file in
// vim with the following line in your vimrc/init.vim:

// autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid dwmblocks & }
