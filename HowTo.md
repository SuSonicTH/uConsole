# A collection of tweeks and howtos

## switch between consoles
in GUI hit `ctrl+alt+fn+[n]` where [n] is 1-6 (you have to press alt+ctrl first and then fn+[n])

in a tty press `alt+fn[n]` where [n] is 1-6 for other ttys and 7 to go beck to GUI

## change console font
If you want the console font to be bigger on bootup and on the tty (not in the UI) you can change the font by executing `sudo dpkg-reconfigure console-setup`

Just select the default values for the first two screens by pressing enter.
* UTF-8 - hit enter
* Guess optimal character set - hit enter
* Then select the font `TerminusBold` and hit enter
* then select a size you like (14x28 seems perfect for me) and hit enter

If you are on a console you see the change immediatly. If you like it you are done, else you can run `sudo dpkg-reconfigure console-setup` again and change the font to your liking.

## boot into console (textmode) start GUI on demand
if you want to boot into console instead of the UI:
* execute `sudo raspi-config` 
* select `System Options`
* select `Boot / Auto Login`
* select `Console` or `Console Autologin`
* select `Finish`

Enjoy faster boot times and feel powerful cause you are using the console.

If you want to start the GUI after booting into console just execute `startx` 
You also can close down the GUI again by going to the start menu clicking `Logout` and selecting `exit to commandline`

