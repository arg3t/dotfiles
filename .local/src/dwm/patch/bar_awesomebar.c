int
width_awesomebar(Bar *bar, BarArg *a)
{
	return a->w;
}

int
draw_awesomebar(Bar *bar, BarArg *a)
{
	int n = 0, scm, remainder = 0, tabw, pad;
	unsigned int i;
	#if BAR_TITLE_LEFT_PAD_PATCH && BAR_TITLE_RIGHT_PAD_PATCH
	int x = a->x + lrpad / 2, w = a->w - lrpad;
	#elif BAR_TITLE_LEFT_PAD_PATCH
	int x = a->x + lrpad / 2, w = a->w - lrpad / 2;
	#elif BAR_TITLE_RIGHT_PAD_PATCH
	int x = a->x, w = a->w - lrpad / 2;
	#else
	int x = a->x, w = a->w;
	#endif // BAR_TITLE_LEFT_PAD_PATCH | BAR_TITLE_RIGHT_PAD_PATCH

	Client *c;
	for (c = bar->mon->clients; c; c = c->next)
		if (ISVISIBLE(c))
			n++;

	if (n > 0) {
		remainder = w % n;
		tabw = w / n;
		for (i = 0, c = bar->mon->clients; c; c = c->next, i++) {
			if (!ISVISIBLE(c))
				continue;
			if (bar->mon->sel == c)
				scm = SchemeTitleSel;
			else if (HIDDEN(c))
				scm = SchemeHid;
			else
				scm = SchemeTitleNorm;

			pad = lrpad / 2;
			#if BAR_CENTEREDWINDOWNAME_PATCH
			if (TEXTW(c->name) < tabw)
				pad = (tabw - TEXTW(c->name) + lrpad) / 2;
			#endif // BAR_CENTEREDWINDOWNAME_PATCH

			drw_setscheme(drw, scheme[scm]);
			drw_text(drw, x, a->y, tabw + (i < remainder ? 1 : 0), a->h, pad, c->name, 0, False);
			drawstateindicator(c->mon, c, 1, x, a->y, tabw + (i < remainder ? 1 : 0), a->h, 0, 0, c->isfixed);
			x += tabw + (i < remainder ? 1 : 0);
		}
	}
	return n;
}

int
click_awesomebar(Bar *bar, Arg *arg, BarArg *a)
{
	int x = 0, n = 0;
	Client *c;

	for (c = bar->mon->clients; c; c = c->next)
		if (ISVISIBLE(c))
			n++;

	c = bar->mon->clients;

	do {
		if (!c || !ISVISIBLE(c))
			continue;
		else
			x += (1.0 / (double)n) * a->w;
	} while (c && a->x > x && (c = c->next));

	if (c) {
		arg->v = c;
		return ClkWinTitle;
	}
	return -1;
}
