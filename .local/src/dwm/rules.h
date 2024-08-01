/*
 __   _______ _____ _____
 \ \ / / ____| ____|_   _|
  \ V /|  _| |  _|   | |
   | | | |___| |___  | |
   |_| |_____|_____| |_|
  Yeet's DWM rules
*/

#ifndef rules_h
#define rules_h

/* xprop(1):
 *	WM_CLASS(STRING) = instance, class
 *	WM_NAME(STRING) = title
 *	WM_WINDOW_ROLE(STRING) = role
 *	_NET_WM_WINDOW_TYPE(ATOM) = wintype
 */
static const Rule rules[] = {

	/* class          instance       title       tags mask     isfloating   floatpos   isterminal noswallow monitor */
{ "discord"          , NULL       , NULL       , 1 << 8    , 0  ,         NULL          , 0  , 0  , -1  },
{ "Mattermost"       , NULL       , NULL       , 1 << 8    , 0  ,         NULL          , 0  , 0  , -1  },
{ "spotify"             , NULL       , NULL       , 1 << 8    , 0  ,         NULL          , 0  , 0  , -1  },
{ "Spotify"             , NULL       , NULL       , 1 << 8    , 0  ,         NULL          , 0  , 0  , -1  },
{ "Signal"          , NULL       , NULL        , 1 << 8    , 0  ,         NULL          , 0  , 0  , -1  },
{ "Brave-browser"    , NULL       , NULL       , 1 << 1    , 0  ,         NULL          , 0  , 0  , -1  },
{ "Firefox"          , NULL       , NULL       , 1 << 1    , 0  ,         NULL          , 0  , 0  , -1  },
{ "firefox"          , NULL       , NULL       , 1 << 1    , 0  ,         NULL          , 0  , 0  , -1  },
{ "Chromium"         , NULL       , NULL       , 1 << 1    , 0  ,         NULL          , 0  , 0  , -1  },
{ "chromium"         , NULL       , NULL       , 1 << 1    , 0  ,         NULL          , 0  , 0  , -1  },
{ "tabbed-surf"      , NULL       , NULL       , 1 << 1    , 0  ,         NULL          , 0  , 0  , -1  },
{ "bitwarden"        , NULL       , NULL       , 1 << 6    , 0  ,         NULL          , 0  , 0  , -1  },
{ "QtPass"           , NULL       , NULL       , 1 << 6    , 0  ,         NULL          , 0  , 0  , -1  },
{ "st-256color"      , NULL       , NULL       , 1 << 0    , 0  ,         NULL          , 1  , 1  , -1  },
{ "gef_helper"       , NULL       , NULL       , 0         , 0  ,         NULL          , 1  , 1  , -1  },
{ "Tor Browser"      , NULL       , NULL       , 1 << 1    , 0  ,         NULL          , 0  , 0  , -1  },
{ "TelegramDesktop"  , NULL       , NULL       , 1 << 8    , 0  ,         NULL          , 0  , 0  , -1  },
{ "thunderbird"      , NULL       , NULL       , 1 << 7    , 0  ,         NULL          , 0  , 0  , -1  },
{ "zoom"             , NULL       , NULL       , 1 << 5    , 0  ,         NULL          , 0  , 0  , -1  },
{ "VirtualBox Manager"        , NULL       , NULL       , 1 << 4    , 0 ,         NULL          , 0  , 0  , -1  },
{ "VirtualBox Machine"        , NULL       , NULL       , 1 << 4    , 0 ,         NULL          , 0  , 0  , -1  },
{ "Microsoft Teams - Preview" , NULL       , NULL       , 1 << 5    , 0 ,         NULL          , 0  , 0  , -1  },
{ "Journal"          , NULL       , NULL       , 1 << 3    , 0 ,         NULL          , 0  , 0  , -1  },
{ "neovide"          , NULL       , NULL       , 1 << 2    , 0 ,         NULL          , 0  , 0  , -1  },
{ "dev.zed.Zed"      , NULL       , NULL       , 1 << 2    , 0 ,         NULL          , 0  , 0  , -1  },
{ "Nemo"             , NULL       , NULL       , 0         , 1     , "50% 50% 1200W 800H"  , 0  , 0  , -1  },
{ "ranger"           , NULL       , NULL       , 0         , 1     , "50% 50% 800W 560H"   , 0  , 0  , -1  },
{ "lf"               , NULL       , NULL       , 0         , 1     , "50% 50% 800W 560H"   , 0  , 0  , -1  },
{ "vim"              , NULL       , NULL       , 0         , 1     , "50% 50% 1000W 700H"  , 0  , 0  , -1  },
{ "stpulse"          , NULL       , NULL       , 0         , 1     , "50% 50% 800W 560H"   , 0  , 0  , -1  },
{ "mpv"              , NULL       , NULL       , 0         , 1     , "100% 1% 600W 350H"   , 0  , 0  , -1  },
{ "neomutt-send"     , NULL       , NULL       , 0         , 1     , "50% 50% 1000W 700H"  , 0  , 0  , -1  },
{ "weather"          , NULL       , NULL       , 0         , 1     , "50% 50% 1200W 800H"  , 0  , 0  , -1  },
{ "center"           , NULL       , NULL       , 0         , 1     , "50% 50% 1000W 600H"  , 0  , 0  , -1  },
{ "htop"             , NULL       , NULL       , 0         , 1     , "50% 50% 1200W 600H"  , 0  , 0  , -1  },
{ "Pavucontrol"      , NULL       , NULL       , 0         , 1     , "50% 50% 1200W 600H"  , 0  , 0  , -1  },
{ "Zathura"          , NULL       , NULL       , 0         , 0     ,         NULL          , 0  , 1  , -1  },
{ "DEA"              , NULL       , NULL       , 0         , 1     ,         NULL          , 0  , 1  , -1  },
{ "Qemu-system-x86_64", NULL      , NULL       , 0         , 1     ,         NULL          , 0  , 1  , -1  },
{ NULL               , "spterm"   , NULL       , SPTAG(0)  , 1     ,         NULL          , 0  , 0  , -1  },
{ NULL               , "spmutt"   , NULL       , SPTAG(1)  , 1     ,         NULL          , 0  , 0  , -1  },
{ NULL               , "spfile"   , NULL       , SPTAG(2)  , 1     ,         NULL          , 0  , 0  , -1  },
{ NULL               , "spcal"    , NULL       , SPTAG(3)  , 1     ,         NULL          , 0  , 0  , -1  },
{ NULL               , "notesnook"   , NULL     , SPTAG(4)  , 1     , "50% 50% 1400W 700H"  , 0  , 0  , -1  },

#ifdef HOSTNAME_desktop
  { NULL               , "cradle"   , NULL     , SPTAG(4)  , 1     , "50% 50% 1400W 700H"  , 0  , 0  , -1  },
#else
  { NULL               , "obsidian"   , NULL     , SPTAG(4)  , 1     , "50% 50% 1400W 700H"  , 0  , 0  , -1  },
#endif
{ NULL               , "sxiv"     , NULL       , 0         , 1     , "100% 1% 600W 350H"   , 1  , 0  , -1  },
{ NULL               , "Kunst"    , NULL       , 0         , 1     , "100% 1% 150W 150H"   , 0  , 0  , -1  },
{ NULL               , NULL       , "SimCrop"  , 0         , 1     , "50% 50% 800W 500H"   , 0   ,0  , -1  },
//{ NULL               , NULL       , NULL       , 0         , 1     ,         NULL          , 0   ,0  , -1  },
};

#endif /* rules_h */

