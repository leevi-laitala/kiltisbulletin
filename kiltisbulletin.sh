#!/bin/bash

# Requires:
# - ImageMagick             for identify command
# - sxiv                    as image preview application
# - mpv                     as video preview application
# - i3                      a window manager which workspaces are used
# - firefox (or equivalent) as a web browser

# i3 supports by default 10 workspaces, which are defined in it's configuration
# file in ~/.config/i3/config.
# The slideshow opens files one by one, each in their own workspace.
# When 10 workspaces are defined, only 10 files can be included in the slideshow
export WORKSPACEMAX=10

# Currently supports only firefox and it's mods
export BROWSER=firefox

# Delay between "slides" in seconds
DELAY=10

# Rewind video back to the beginning when they are shown.
REWINDVIDEO=1

# Source functions from 'include/util.sh'
SCRIPTDIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
if [[ ! -e "$SCRIPTDIR/include/util.sh"  ]]; then
    echo "Could not locate file: 'util.sh'"
    exit 1
else
    # shellcheck source=./util.sh
    source "$SCRIPTDIR/include/util.sh"
fi

# Path to directory that contains the files
[ -z "${FILESPATH}" ] && \
    {   msg="FILESPATH env variable is left undefined.\n"
        msg+="Will be set to '"$SCRIPTDIR/files"'"
        warning "$msg"
        FILESPATH="$SCRIPTDIR/files"
    }

# Check if the number of files that are to be included in the "slideshow"
# exceed the number of available workspaces
[ $(ls "$FILESPATH" | wc -l) -gt $WORKSPACEMAX ] && \
    fatal "Too many files. Only $WORKSPACEMAX files can be handled currently"

# Go through files in direcotry defined in FILESPATH and open them in
# appropriate applications
parseFiles

# Start "slideshow"
while :
do
    # Got to next slide
    i3-msg "workspace next" > /dev/null

    # Rewind video if mpv player is present
    if $REWINDVIEO; then
        rewindVideo
    fi

    # Wait
    sleep $DELAY
done

