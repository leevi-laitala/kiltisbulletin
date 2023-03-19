#!/bin/bash

# Print error and exit
function fatal {
    # Append \t after newlines in input
    MSG="$(echo "$1" | sed 's/\\n/\\n\\t/')"

    # Set color to red when printing error message
    tput setaf 1; echo -e "ERROR:\t$MSG"; tput setaf 7
    exit 1
}

# Same as error, but does not exit the application
function warning {
    MSG="$(echo "$1" | sed 's/\\n/\\n\\t/')"
    tput setaf 3; echo -e "WARN:\t$MSG"; tput setaf 7
}

function getNewWorkspace {
    CURRENT=$(i3-msg -t get_workspaces | \
        jq -r '.[] | select(.focused==true).name')
    
    LARGEST=$(i3-msg -t get_workspaces | \
        jq -r '.[] | .name' | tail -1)

    [ $LARGEST -lt $WORKSPACEMAX ] && \
        i3-msg "workspace $(( $CURRENT + 1 ))"
}

# Open video with given filename
function openVideo {
    FNAME="$1"

    # Expand tilde character to /home/$USER in case such is present in
    # given path
    FNAME="${FNAME/#\~/$HOME}"

    [ ! -e "$FNAME" ] && fatal "Video file does not exist"

    # Open video in background, using following flags:
    # --really-quiet    don't print anything to stdout
    # --no-audio        self explanotory
    # --fs              fullscreen
    # --panscan=1.0     no clue how works, scales video to fit screen
    # --loop-file       loops video
    mpv --really-quiet --no-audio -fs --panscan=1.0 --loop-file "$FNAME" &
}

function openWebpage {
    FNAME="$1"

    URL="$(cat "$FNAME")"

    # Open url in given firefox-based browser, using following flags:
    # --kiosk           kiosk mode, basically open in fullscreen
    # --new-window      enables multiple instances of the browser to be ran
    #                   in different workspaces
    $BROWSER --kiosk --new-window "$URL" &
}

function openImage {
    FNAME="$1"

    # Expand tilde character to /home/$USER in case such is present in
    # given path
    FNAME="${FNAME/#\~/$HOME}"

    [ ! -e "$FNAME" ] && fatal "Image file does not exist"
    
    # Open image file using sxiv with the following flags:
    # -b                don't show info bar
    # -s w              sets mode to fit the image widthwise
    # -f                fullscreen
    sxiv -b -s w -f "$FNAME" &
}

# Evaluate the file type by using "file" command.
# This is not great, but I guess works for now
function parseFile {
    FILE="$1"

    # Regex patterns
    IMAGE="(PNG|WEBP|JPEG|TIFF)"
    VIDEO="(MP4|WebM|Matroska|GIF)"
    WEBPAGE="(ASCII)"

    getNewWorkspace

    EXT="$(grep -oE "$IMAGE" <<<"$(file "${FILE}")")"
    [ -n "$EXT" ] && \
        { openImage "$FILE" && sleep 2; return ; }

    EXT="$(grep -oE "$VIDEO" <<<"$(file "${FILE}")")"
    [ -n "$EXT" ] && \
        { openVideo "$FILE" && sleep 2; return ; }

    EXT="$(grep -oE "$WEBPAGE" <<<"$(file "${FILE}")")"
    [ -n "$EXT" ] && \
        { openWebpage "$FILE" && sleep 7; return ; }
}

function parseFiles {
    # Check that the specified direcotry exists and contain files
    [ ! -d "$FILESPATH" ] && \
        fatal "Directory defined in FILESPATH does not exist"

    [ -z "$(ls -A "$FILESPATH")" ] && \
        fatal "Directory specified in FILESPATH env varaible is empty"

    export -f parseFile openImage openVideo openWebpage getNewWorkspace
    find "$FILESPATH" -type f -exec bash -c 'parseFile "$0"' {} \;
}
