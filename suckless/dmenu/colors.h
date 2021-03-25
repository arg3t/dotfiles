/* This file is used for color settings */

static const char *colors[SchemeLast][2] = {
	/*     fg         bg       */
	[SchemeNorm] = { "#e5e9f0", "#0f111a" },
	[SchemeSel] = { "#0f111a", "#bf616a" },
	[SchemeOut] = { "#000000", "#00ffff" },
	[SchemeNormHighlight] = { "#88c0d0", "#0f111a" },
	[SchemeSelHighlight] = { "#88c0d0", "#bf616a" },
	// [SchemeHp] = { "#e5e9f0", "#4c566a" },
};


static const unsigned int bgalpha = 0xFF;
static const unsigned int fgalpha = OPAQUE;


static const unsigned int alphas[SchemeLast][2] = {
	/*		fgalpha		bgalphga	*/
	[SchemeNorm] = { fgalpha, bgalpha },
	[SchemeSel] = { fgalpha, bgalpha },
	[SchemeOut] = { fgalpha, bgalpha },
};
