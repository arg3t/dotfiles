This program provides a scroll back buffer for a terminal like st(1).  It
should run on any Unix-like system.

At the moment it is in an experimental state.  Its not recommended for
productive use.

The initial version of this program is from Roberto E. Vargas Caballero:
	https://lists.suckless.org/dev/1703/31256.html

What is the state of scroll?

The project is faced with some hard facts, that our original plan is not doable
as we thought in the first place:

 1. [crtl]+[e] is used in emacs mode (default) on the shell to jump to the end
    of the line.  But, its also used so signal a scroll down mouse event from
    terminal emulators to the shell an other programs.

    - A workaround is to use vi mode in the shell.
    - Or to give up mouse support (default behavior)

 2. scroll could not handle backward cursor jumps and editing of old lines
    properly.  We just handle current line editing and switching between
    alternative screens (curses mode).  For a proper end user experience we
    would need to write a completely new terminal emulator like screen or tmux.

What is the performance impact of scroll?

	indirect	OpenBSD
-------------------------------
	0x		 7.53 s
	1x		10.10 s
	2x		12.00 s
	3x		13.73 s
