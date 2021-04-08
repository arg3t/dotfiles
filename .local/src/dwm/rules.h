static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 *	WM_WINDOW_ROLE(STRING) = role
	 *	_NET_WM_WINDOW_TYPE(ATOM) = wintype
	 */
	RULE(.class = "discord", .tags = 1 << 8)
	RULE(.class = "firefoxdeveloperedition", .tags = 1 << 1)
	RULE(.class = "Brave-browser", .tags = 1 << 1)
	RULE(.class = "firefox", .tags = 1 << 1)
	RULE(.class = "tabbed-surf", .tags = 1 << 1)
	RULE(.class = "bitwarden", .tags = 1 << 6)
	RULE(.class = "QtPass", .tags = 1 << 6)
	RULE(.class = "qtpass", .tags = 1 << 6)
	RULE(.class = "Bitwarden", .tags = 1 << 6)
	RULE(.class = "Mailspring", .tags = 1 << 7)
	RULE(.class = "Thunderbird", .tags = 1 << 7)
	RULE(.class = "st-256color", .tags = 1 << 0, .isfloating=0)
	RULE(.class = "Tor Browser", .tags = 1 << 1)
	RULE(.class = "Chromium", .tags = 1 << 1)
	RULE(.class = "TelegramDesktop", .tags = 1 << 8)
	RULE(.class = "whatsapp-nativefier-d52542", .tags = 1 << 8)
	RULE(.class = "Sublime_Text", .tags = 1 << 2)
	RULE(.class = "code-oss", .tags = 1 << 2)
	RULE(.class = "jetbrains-idea", .tags = 1 << 2)
	RULE(.class = "Nemo", .isfloating = 1, .floatpos="50% 50% 1200W 800H")
	RULE(.class = "Spotify", .tags = 1 << 9)
	RULE(.instance = "spterm", .tags = SPTAG(0), .isfloating = 1)
	RULE(.class = "spfeh", .tags = SPTAG(1), .isfloating = 1)
	RULE(.instance = "spmutt", .tags = SPTAG(2), .isfloating = 1)
	RULE(.instance = "spfile", .tags = SPTAG(3), .isfloating = 1)
	RULE(.instance = "spmusic", .tags = SPTAG(4), .isfloating = 1)
	RULE(.instance = "spcal", .tags = SPTAG(5), .isfloating = 1)
	/* Terminal Window Rules */
	RULE(.class = "ranger", 0, .isfloating = 1, .floatpos="50% 50% 800W 560H")
	RULE(.class = "lf", 0, .isfloating = 1, .floatpos="50% 50% 800W 560H")
	RULE(.class = "vim", 0, .isfloating = 1, .floatpos="50% 50% 1000W 700H")
	RULE(.class = "stpulse", 0, .isfloating = 1, .floatpos="50% 50% 800W 560H")
	RULE(.class = "mpv", 0, .isfloating = 1, .floatpos="100% 1% 600W 350H")
	RULE(.instance = "sxiv", 0, .isfloating = 1, .floatpos="100% 1% 600W 350H")
	RULE(.class = "neomutt-send", 0, .isfloating = 1, .floatpos="50% 50% 1000W 700H")
	//RULE(.class = "Zathura", 0, .isfloating = 1, .floatpos="100% 50% 700W 1000H")
	//RULE(.class = "Surf", 0, .isfloating = 1, .floatpos="100% 100% 800W 1200H")
	RULE(.class = "weather", 0, .isfloating = 1, .floatpos="50% 50% 1200W 800H")
	RULE(.class = "center", 0, .isfloating = 1, .floatpos="50% 50% 1000W 600H")
	RULE(.class = "htop", 0, .isfloating = 1, .floatpos="50% 50% 1200W 600H")
	RULE(.title = "SimCrop", 0, .isfloating = 1, .floatpos="50% 50% 800W 500H")

};