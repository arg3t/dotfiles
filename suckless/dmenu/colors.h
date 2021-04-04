/* This file is used for color settings */

static const char *colors[SchemeLast][2] = {
	/*     fg         bg       */
	[SchemeNorm] = { "#e5e9f0", "#0f111a" },
	[SchemeSel] = { "#0f111a", "#bf616a" },
	[SchemeOut] = { "#000000", "#00ffff" },
	[SchemeNormHighlight] = { "#81a1c1", "#0f111a" },
	[SchemeSelHighlight] = { "#88c0d0", "#bf616a" },
};


static double opacity = 1.0;                /* -o  option; defines alpha translucency */

static const unsigned int baralpha = 0xFF;
static const unsigned int borderalpha = OPAQUE;


static const unsigned int alphas[][3]      = {
	/*               fg      bg        border     */
	[SchemeNorm] = { OPAQUE, baralpha, borderalpha },
	[SchemeSel]  = { OPAQUE, baralpha, borderalpha },
	[SchemeOut] = { OPAQUE, baralpha, borderalpha },
	[SchemeNormHighlight] = { OPAQUE, baralpha, borderalpha },
	[SchemeSelHighlight] = { OPAQUE, baralpha, borderalpha },
};
