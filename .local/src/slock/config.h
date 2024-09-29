#define BEZEL_THICKNESS 16

/* user and group to drop privileges to */
static const char *user = "nobody";
static const char *group = "nogroup";

static const char *colorname[NUMCOLS] = {
    [INIT] = "#black",    /* after initialization */
    [INPUT1] = "#89b4fa", /* during input */
    [INPUT2] = "#a6e3a1", /* during input */
    [FAILED] = "#f38ba8", /* wrong password */
};

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 0;

/*Enable blur*/
// #define BLUR
/*Set blur radius*/
static const int blurRadius = 20;
/*Enable Pixelation*/
#define PIXELATION
/*Set pixelation radius*/
static const int pixelSize = 8;

/* insert grid pattern with scale 1:1, the size can be changed with logosize */
static const int logosize = 1;
static const int logow =
    1920; /* grid width and height for right center alignment*/
static const int logoh = 1080;

static XRectangle rectangles[9] = {
    /* x	y	w	h */
    {0, 0, 0xFFFF, BEZEL_THICKNESS},
    {0, 0, BEZEL_THICKNESS, 0xFFFF},
    {0, -1, 0xFFFF, BEZEL_THICKNESS},
    {-1, 0, BEZEL_THICKNESS, 0xFFFF},

};
