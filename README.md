# Kiltisbulletin

A shell script to manage a simple digital bulletin board.

Supports videos, images and websites.


## How it works

Kiltisbulletin creates a slideshow from files that are present in a defined
directory. Each file is opened in a different i3 workspace, which are like
virtual desktops, that can contain their own set of windows.

This means that the script requires i3 window manager to be intalled on the 
host system. 

## Requirements

- X server
- i3 window manager
- ImageMagick
- sxiv
- mpv
- firefox (or equivalent)


## Configuration

#### Slides

The slides, or files that you want to include in the slideshow. The location of
this directory that contain files is by default searched in `files` directory
under the repository root.

Custom location for the directory can be defined via `FILESPATH` environment
variable.

Supported files include images, videos and websites. Currently each file type
is evaluated using the `file` command and matching a regex pattern from it's
output. The regex patterns are found inside `parseFile` function, which is 
located in `include/util.sh` file. 

Currently only JPG, PNG, TIFF and WEBP image types are checked for. For video
files MP4, WebM, Matroska and GIF types are checked for.

Webpages are included as URL containing text files.

#### Content viewers

Images are viewed using `sxiv`, videos using `mpv` and webpages using `firefox`.

These can be changed by modifying `openImage`, `openVideo` and `openWebpage`
functions to open files in different applications.

Custom content viewers can be easily added in `parseFile` function. 

Create some rule, which by default is a regex match from `file` command. And
a command that is executed when the criteria defined in given rule is met.

If adding a bash function, remember to include the function name in 

#### Video viewer and rewind function

The script by default rewinds video when slide containing `mpv` is presented.
This isn't implemented in any elegant way. When switching to workspace which
contains instance of `mpv`, a down key is pressed using `xdotool`. By default
down key is bound to skip the video by one minute backwards.

If using different video viewer, this method won't probably work.

#### Wait time between applications

When opening a file in new workspace, it is essential that a window for the 
file viewer application is created before proceeding to next workspace.

To make sure that the application has fully started is done by waiting for 
some time when launching given viewer app.

Wait time is defined in `parseFile` function found in `include/util.sh` file.
By default is set as 10 seconds.

## Automation

#### Launch when X starts

Just add `exec --no-startup-id /path/to/kiltisbulletin.sh` in your i3 config 
file.

#### Prevent screen from going to sleep

Create `/etc/X11/xorg.conf` file with these lines included:

```
Section "ServerLayout"
    Identifier "Layout"
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
EndSection
```

#### Automatically start x when logging in

[Autostart X at login](https://wiki.archlinux.org/title/Xinit#Autostart_X_at_login)

#### Automatically log in

[Automatic login to virtual console](https://wiki.archlinux.org/title/Getty#Automatic_login_to_virtual_console)


