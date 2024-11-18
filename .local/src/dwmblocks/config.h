/*
 __   _______ _____ _____
 \ \ / / ____| ____|_   _|
  \ V /|  _| |  _|   | |
   | | | |___| |___  | |
   |_| |_____|_____| |_|
  Yeet's DWMBlocks Config
*/

#define PATH(name) USERNAME "/.local/bin/status-bar/" name

static Block blocks[] = {
    //	{ "", PATH("clipboard"),		120,		28},
    {"", PATH("security"), 120, 28},
    {"", PATH("mpv"), 1, 20},
    {"", PATH("screensaver"), 120, 19},
    {"", PATH("dunst"), 120, 18},
    //	{ "", PATH("mail")       ,					  120,
    // 23}   ,
    {"", PATH("keyboard"), 120, 24},
    {"", PATH("redshift"), 120, 29},
    //	{ "", PATH("mpc")        ,				  	240,
    // 29}   ,
    //	{ "", PATH("hamster")    ,				  	60 ,
    // 31}   ,
    {"", PATH("bluetooth"), 120, 26},
    {"", PATH("timer"), 5, 30},
    //	{ "", PATH("mconnect")   ,			  120    ,
    // 20},
    //	{ "", PATH("todo")       ,					  120,
    // 27}   ,
    //	{ "", PATH("nextcloud")  ,			600      ,
    // 25},
    {"", PATH("memory"), 120, 21},
    {"", PATH("cpu-temp"), 30, 17},
    {"", PATH("weather"), 60, 16},
    {"", PATH("arch"), 120, 15},
    {"", PATH("volume"), 5, 14},
    {"", PATH("network"), 120, 13},
    {"", PATH("battery"), 60, 12},
    {"", PATH("time"), 30, 11},
    {"", PATH("date"), 240, 22},
};

// Sets delimiter between status commands. NULL character ('\0') means no
// delimiter.
static char *delim = " | ";

// autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd
// ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid
// dwmblocks & }
