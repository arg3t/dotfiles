//
//  theme.h
//  dwm
//
//  Created by Yigit Colakoglu on 04/12/21.
//  Copyright 2021. Yigit Colakoglu. All rights reserved.
//

#ifndef theme_h
#define theme_h

#include <unistd.h>

static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int gappih    = 20;       /* horiz inner gap between windows */
static const unsigned int gappiv    = 10;       /* vert inner gap between windows */
static const unsigned int gappoh    = 10;       /* horiz outer gap between windows and screen edge */
static const unsigned int gappov    = 30;       /* vert outer gap between windows and screen edge */
static       int smartgaps          = 0;        /* 1 means no outer gap when there is only one window */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const int user_bh            = 27;        /* 0 means that dwm will calculate bar height, >= 1 means dwm will user_bh as bar height */
static const int horizpadbar        = 2;        /* horizontal padding for statusbar */
static const int vertpadbar         = 0;        /* vertical padding for statusbar */
static const int vertpad            = 10;       /* vertical padding of bar */
static const int sidepad            = 10;       /* horizontal padding of bar */
static int floatposgrid_x           = 5;        /* float grid columns */
static int floatposgrid_y           = 5;        /* float grid rows */

char hostname[1024];

#ifdef HOSTNAME_tarnag
  static const char *fonts[]          = { "CaskaydiaCove Nerd Font:size=12" };
#else
  static const char *fonts[]          = { "CaskaydiaCove Nerd Font:size=10" };
#endif

static const char fore[]   = "#cdd6f4";
static const char back[]   = "#1e1e2e";
static const char border[] = "#3a575c";
static const char col0[]   = "#3b4252";
static const char col1[]   = "#bf616a"; /* red */
static const char col2[]   = "#a3be8c"; /* green */
static const char col3[]   = "#ebcb8b"; /* yellow */
static const char col4[]   = "#81a1c1"; /* light_blue */
static const char col5[]   = "#a48ead"; /* puple */
static const char col6[]   = "#88c0d0"; /* blue */
static const char col7[]   = "#e5e9f0"; /* white */
static const char col8[]   = "#4c566a"; /* gray */

static char *colors[][3] = {
	/*                       fg                bg                border                float */
	[SchemeNorm]         = { fore, back, border},
	[SchemeSel]          = { fore, back, col1},
	[SchemeStatus]         = { fore, back, border},
	[SchemeTagsNorm]     = { fore, back, border},
	[SchemeTagsSel]      = { back, col1, border},
	[SchemeInfoSel]          = { back, col4, border},
};


#endif /* theme_h */

