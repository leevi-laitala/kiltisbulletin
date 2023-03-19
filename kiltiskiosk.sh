#!/bin/bash

# Requires:
# - ImageMagick             for identify command
# - sxiv                    as image preview application
# - mpv                     as video preview application
# - i3                      a window manager which workspaces are used
# - firefox (or equivalent) as a web browser

# This is the default set in "~/.config/i3/config"
export WORKSPACEMAX=10

# Currently supports only firefox and it's mods
export BROWSER=librewolf

# Delay between "slides" in seconds
DELAY=10

if [[ ! -e "$(pwd)/include/util.sh"  ]]; then
    echo "Could not locate file: 'util.sh'"
    exit 1
else
    # shellcheck source=./util.sh
    source "include/util.sh"
fi

# Path to directory that contains the files
[ -z "${FILESPATH}" ] && \
    {   msg="FILESPATH env variable is left undefined.\n"
        msg+="Will be set to '"$(pwd)/files"'"
        warning "$msg"
        FILESPATH="$(pwd)/files"
    }

[ $(ls "$FILESPATH" | wc -l) -gt $WORKSPACEMAX ] && \
    fatal "Too many files. Only $WORKSPACEMAX files can be handled currently"

# Go through files in direcotry defined in FILESPATH and open them in
# appropriate applications
parseFiles

# "slideshow"
while :
do
    i3-msg "workspace next"
    sleep $DELAY
done

