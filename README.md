# Fr1nge's Dotfiles

Welcome to my dungeon. Here, I keep all my configuration files in case I have a stroke and lose all my memory. You're very welcome to explore and use anything in this repository. Have fun!

## My Setup: 

*  Arch Linux
* DWM ([dwm-flexipatch](https://github.com/bakkeby/dwm-flexipatch))
* dmenu
* st (simple terminal)
* dunst
* zsh with powerlevel10k and antibody
* tmux
* zathura
* [Material Ocean](https://github.com/material-ocean/) color scheme for pretty much everything

## Installation

Just run `git clone --recurse-submodules github.com/yigitcolakoglu/dotfiles.git ~/.dotfiles`. This will download everything you need. After that, I have a list of all the packages I have installed on my machine in the directory chroot/. If you have any problems regarding the setup, you should first check whether you have missing packages. After the clone process, it is pretty straightforward, you can run the `install.sh` script which creates necessary symlinks. Finally, DO NOT FORGET to run sudo make clean install in each directory under suckless, I also have a script named build.sh in that directory which does that automatically. 

## Some eye candy

![Workspace 1](screenshots/w1.jpg) 

![Workspace 1](screenshots/w2.jpg) 

![Workspace 1](screenshots/w4.jpg) 

## TODOs

* Improve the go function written in surf
* Add the documentation for all the keybinds 
* ~Improve the way indicators look~
* ~!!! High priority add an indicator for insert mode~