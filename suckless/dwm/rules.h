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
	RULE(.class = "st-256color", .tags = 1 << 0)
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
	RULE(.instance = "spsxiv", .tags = SPTAG(0), .isfloating = 1)
