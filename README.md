# Fr1nge's Dotfiles

Welcome to my dungeon. Here, I keep all my configuration files in case I have a stroke an
d lose all my memory. You're very welcome to explore and use anything in this repository. 
Have fun! Another copy of all of this is [here](https://git.yigitcolakoglu.com/yigitcolakoglu/dotfiles).  
*For instructions on installattion, see [Installation](#Installation). I highly recommend you follow them.*

## My Setup: 

* Arch Linux
* DWM ([dwm-flexipatch](https://github.com/bakkeby/dwm-flexipatch))
* dmenu
* st (simple terminal)
* dunst
* zsh with powerlevel10k and antibody
* tmux
* zathura
* [Material Ocean](https://github.com/material-ocean/) color scheme for pretty much everything
* [Pomme Page](https://github.com/kikiklang/pomme-page)

## Installation

I use bare repositories to track my dotfiles, of course you don't have to do that and you can download and manually link everything you need. But if
you want to use bare repositories as well. I sugggest you clone this repository first and run the following commands.

```sh
git clone --depth 4 --bare https://github.com/<your_username>/dotfiles.git  ~/.dotfiles.git
cd ~
alias dots="git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME"
dots show main:install.sh | sh
```

This will download everything you need. After that, I have a list of all the packages I have installed on my machine in the directory arch-setup/.
If you have any problems regarding the setup, you should first check whether you have missing packages. 
After the clone process, it is pretty straightforward, you can run the `install.sh` script which creates necessary symlinks. 
You might want to edit your crontab and the ~/.config/config.env.

## Some eye candy

![Reddit Post SS](https://i.redd.it/0yypvtsinyo61.png) 

## TODOS

* [X] Neomutt further config
* [X] Dwmblocks entry for tracking last mailsync time
* [X] Fix ISO4755 and externalpipe conflict
* [ ] Better documentation (Perhaps an auto-documentation tool written in python?)
* [X] Dmenu for restarting certain processes like dwm, dwmblocks, dunst, mconnect
