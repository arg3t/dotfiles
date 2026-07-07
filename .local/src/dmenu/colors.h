/* This file is used for color settings */

static const unsigned int border_width = 0; /* Fix border transparency */
static const char *colors[SchemeLast][2] = {
	/*     fg         bg       */
	[SchemeNorm] = { "#cdd6f4", "#1e1e2e" },
	[SchemeSel] = { "#1e1e2e", "#89dceb" },
	[SchemeOut] = { "#000000", "#89dceb" },
	[SchemeNormHighlight] = { "#cdd6f4", "#1e1e2e", "#1e1e2e" },
	[SchemeSelHighlight] = { "#1e1e2e", "#89dceb", "#a6e3a1" },
};


static double opacity = 1.0;                /* -o  option; defines alpha translucency */

static const unsigned int baralpha = 0xFF;
static const unsigned int borderalpha = 0xFF;


static const unsigned int alphas[][3]      = {
	/*               fg      bg        border     */
	[SchemeNorm] = { OPAQUE, baralpha, borderalpha },
	[SchemeSel]  = { OPAQUE, baralpha, borderalpha },
	[SchemeOut] = { OPAQUE, baralpha, borderalpha },
	[SchemeNormHighlight] = { OPAQUE, baralpha, borderalpha },
	[SchemeSelHighlight] = { OPAQUE, baralpha, borderalpha },
};
