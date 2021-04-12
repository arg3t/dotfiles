//
//  rules.h
//  dwm
//
//  Created by Yigit Colakoglu on 04/12/21.
//  Copyright 2021. Yigit Colakoglu. All rights reserved.
//

#ifndef rules_h
#define rules_h

/* xprop(1):
 *	WM_CLASS(STRING) = instance, class
 *	WM_NAME(STRING) = title
 *	WM_WINDOW_ROLE(STRING) = role
 *	_NET_WM_WINDOW_TYPE(ATOM) = wintype
 */
static const Rule rules[] = {

	/* class      instance    title       tags mask     isfloating   floatpos   monitor */
	{ "discord", NULL, NULL, 1 << 8, NULL, NULL, -1},
	{ "firefoxdeveloperedition", NULL, NULL, 1 << 1, NULL, NULL, -1},
	{ "Brave-browser", NULL, NULL, 1 << 1, NULL, NULL, -1},
	{ "firefox", NULL, NULL, 1 << 1, NULL, NULL, -1},
	{ "tabbed-surf", NULL, NULL, 1 << 1, NULL, NULL, -1},
	{ "bitwarden", NULL, NULL, 1 << 6, NULL, NULL, -1},
	{ "QtPass", NULL, NULL, 1 << 6, NULL, NULL, -1},
	{ "qtpass", NULL, NULL, 1 << 6, NULL, NULL, -1},
	{ "Bitwarden", NULL, NULL, 1 << 6, NULL, NULL, -1},
	{ "Mailspring", NULL, NULL, 1 << 7, NULL, NULL, -1},
	{ "Thunderbird", NULL, NULL, 1 << 7, NULL, NULL, -1},
	{ "st-256color", NULL, NULL, 1 << 0, NULL, NULL, -1},
	{ "Tor Browser", NULL, NULL, 1 << 1, NULL, NULL, -1},
	{ "Chromium", NULL, NULL, 1 << 1, NULL, NULL, -1},
	{ "TelegramDesktop", NULL, NULL, 1 << 8, NULL, NULL, -1},
	{ "whatsapp-nativefier-d52542", NULL, NULL, 1 << 8, NULL, NULL, -1},
	{ "Sublime_Text", NULL, NULL, 1 << 2, NULL, NULL, -1},
	{ "code-oss", NULL, NULL, 1 << 2, NULL, NULL, -1},
	{ "jetbrains-idea", NULL, NULL, 1 << 2, NULL, NULL, -1},
	{ "Spotify", NULL, NULL, 1 << 9, NULL, NULL, -1},
	{ "Nemo", NULL, NULL, 0, 1, "50% 50% 1200W 800H", -1},
	{ "ranger", NULL, NULL, 0, 1, "50% 50% 800W 560H", -1},
	{ "lf", NULL, NULL, 0, 1, "50% 50% 800W 560H", -1},
	{ "vim", NULL, NULL, 0, 1, "50% 50% 1000W 700H", -1},
	{ "stpulse", NULL, NULL, 0, 1, "50% 50% 800W 560H", -1},
	{ "mpv", NULL, NULL, 0, 1, "100% 1% 600W 350H", -1},
	{ "neomutt-send", NULL, NULL, 0, 1, "50% 50% 1000W 700H", -1},
	{ "weather", NULL, NULL, 0, 1, "50% 50% 1200W 800H", -1},
	{ "center", NULL, NULL, 0, 1, "50% 50% 1000W 600H", -1},
	{ "htop", NULL, NULL, 0, 1, "50% 50% 1200W 600H", -1},
	{ "spfeh", NULL, NULL, SPTAG(1), 1, NULL, -1},
	{ NULL, "spterm", NULL, SPTAG(0), 1, NULL, -1},
	{ NULL, "spmutt", NULL, SPTAG(2), 1, NULL, -1},
	{ NULL, "spfile", NULL, SPTAG(3), 1, NULL, -1},
	{ NULL, "spmusic", NULL, SPTAG(4), 1, NULL, -1},
	{ NULL, "spcal", NULL, SPTAG(5), 1, NULL, -1},
	{ NULL, "sxiv", NULL, 0, 1, "100% 1% 600W 350H", -1},
	{ NULL, "Kunst", NULL, 0, 1, "100% 1% 150W 150H", -1},
	//RULE(.class = "Zathura", 0, .isfloating = 1, .floatpos="100% 50% 700W 1000H")
	//RULE(.class = "Surf", 0, .isfloating = 1, .floatpos="100% 100% 800W 1200H")
	{ NULL, NULL, "SimCrop", 0, 1, "50% 50% 800W 500H", NULL}
};

#endif /* rules_h */

