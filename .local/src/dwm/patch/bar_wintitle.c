int
width_wintitle(Bar *bar, BarArg *a)
{
	return a->w;
}

int
draw_wintitle(Bar *bar, BarArg *a)
{
	#if BAR_TITLE_LEFT_PAD_PATCH && BAR_TITLE_RIGHT_PAD_PATCH
	int x = a->x + lrpad / 2, w = a->w - lrpad;
	#elif BAR_TITLE_LEFT_PAD_PATCH
	int x = a->x + lrpad / 2, w = a->w - lrpad / 2;
	#elif BAR_TITLE_RIGHT_PAD_PATCH
	int x = a->x, w = a->w - lrpad / 2;
	#else
	int x = a->x, w = a->w;
	#endif // BAR_TITLE_LEFT_PAD_PATCH | BAR_TITLE_RIGHT_PAD_PATCH
	Monitor *m = bar->mon;
	int pad = lrpad / 2;

	if (!m->sel) {
		drw_setscheme(drw, scheme[SchemeTitleNorm]);
		drw_rect(drw, x, a->y, w, a->h, 1, 1);
		return 0;
	}

	drw_setscheme(drw, scheme[m == selmon ? SchemeTitleSel : SchemeTitleNorm]);
	#if BAR_IGNORE_XFT_ERRORS_WHEN_DRAWING_TEXT_PATCH
	XSetErrorHandler(xerrordummy);
	#endif // BAR_IGNORE_XFT_ERRORS_WHEN_DRAWING_TEXT_PATCH
	#if BAR_CENTEREDWINDOWNAME_PATCH
	if (TEXTW(m->sel->name) < w)
		pad = (w - TEXTW(m->sel->name) + lrpad) / 2;
	#endif // BAR_CENTEREDWINDOWNAME_PATCH
	drw_text(drw, x, a->y, w, a->h, pad, m->sel->name, 0, False);
	#if BAR_IGNORE_XFT_ERRORS_WHEN_DRAWING_TEXT_PATCH
	XSync(dpy, False);
	XSetErrorHandler(xerror);
	#endif // BAR_IGNORE_XFT_ERRORS_WHEN_DRAWING_TEXT_PATCH
	drawstateindicator(m, m->sel, 1, x, a->y, w, a->h, 0, 0, m->sel->isfixed);
	return 1;
}

int
click_wintitle(Bar *bar, Arg *arg, BarArg *a)
{
	return ClkWinTitle;
}


