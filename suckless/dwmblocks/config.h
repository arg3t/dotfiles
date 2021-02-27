
#define PATH(name)			"/home/yigit/.scripts/status-bar/"name

static Block blocks[] = {

	{ "", PATH("clipboard"),			30,			18},
	{ "", PATH("cpu-temp"),				30,			17},
	{ "", PATH("weather"),				60,			16},
	{ "", PATH("arch"),						120,		15},
	{ "", PATH("volume"),					120,		14},
	{ "", PATH("network"),				120,		13},
	{ "", PATH("battery"),				60,			12},
//	{ "", PATH("time"),					 	30,			11},
};

//Sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char *delim = " | ";

// Have dwmblocks automatically recompile and run when you edit this file in
// vim with the following line in your vimrc/init.vim:

// autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid dwmblocks & }
