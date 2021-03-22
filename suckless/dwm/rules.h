static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 *	WM_WINDOW_ROLE(STRING) = role
	 *	_NET_WM_WINDOW_TYPE(ATOM) = wintype
	 */
	RULE(.class = "discord", .tags = 1 << 8)
	RULE(.class = "firefoxdeveloperedition", .tags = 1 << 1)
	RULE(.class = "tabbed-surf", .tags = 1 << 1)
	RULE(.class = "tabbed", .tags = 1 << 1)
	RULE(.class = "bitwarden", .tags = 1 << 6)
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
	RULE(.class = "Nemo", .tags = 1 << 3)
	RULE(.class = "Spotify", .tags = 1 << 9)
	RULE(.instance = "spterm", .tags = SPTAG(0), .isfloating = 1)
	RULE(.class = "spfeh", .tags = SPTAG(1), .isfloating = 1)
	RULE(.instance = "spmutt", .tags = SPTAG(2), .isfloating = 1)
	RULE(.class = "ranger", 0, .isfloating = 1, .floatpos="50% 50% 800W 560H")
	RULE(.class = "vim", 0, .isfloating = 1, .floatpos="50% 50% 800W 560H")
	RULE(.class = "stpulse", 0, .isfloating = 1, .floatpos="50% 50% 800W 560H")
	RULE(.class = "mpv", 0, .isfloating = 1, .floatpos="100% 1% 600W 350H")
	RULE(.instance = "sxiv", 0, .isfloating = 1, .floatpos="100% 1% 600W 350H")
	RULE(.class = "neomutt-send", 0, .isfloating = 1, .floatpos="50% 50% 1000W 700H")
	RULE(.class = "Zathura", 0, .isfloating = 1, .floatpos="100% 50% 700W 1000H")
	RULE(.class = "weather", 0, .isfloating = 1, .floatpos="50% 50% 1200W 800H") // Why did I put this here?
	RULE(.class = "center", 0, .isfloating = 1, .floatpos="50% 50% 1000W 600H") // Why did I put this here?
	RULE(.class = "htop", 0, .isfloating = 1, .floatpos="50% 50% 1200W 600H") // Why did I put this here?
	RULE(.title = "SimCrop", 0, .isfloating = 1, .floatpos="50% 50% 800W 500H") 

};
