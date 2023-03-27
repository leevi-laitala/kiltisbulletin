#!/bin/bash

LOGFILE="/tmp/kiltisbulletin_log_$(date +'%Y-%m-%d_%H:%M').txt"

# Print error and exit
function fatal {
    # Append \t after newlines in input
    MSG="$(echo "$1" | sed 's/\\n/\\n\\t/')"

    # Set color to red when printing error message
    tput setaf 1; echo -e "ERROR:\t$MSG"; tput setaf 7

    echo -e "$(date +'%Y-%m-%d_%H:%M') --- ERROR: $1" >> "$LOGFILE"

    exit 1
}

# Same as error, but does not exit the application
function warning {
    MSG="$(echo "$1" | sed 's/\\n/\\n\\t/')"
    tput setaf 3; echo -e "WARN:\t$MSG"; tput setaf 7
echo -e "$(date +'%Y-%m-%d_%H:%M') - WARNING: $1" >> "$LOGFILE"
}

function getNewWorkspace {
    CURRENT=$(i3-msg -t get_workspaces | \
        jq -r '.[] | select(.focused==true).name')
    
    LARGEST=$(i3-msg -t get_workspaces | \
        jq -r '.[] | .name' | tail -1)

    [ $LARGEST -lt $WORKSPACEMAX ] && \
        i3-msg "workspace $(( $CURRENT + 1 ))"
}

# Rewind video back to the beginning
function rewindVideo {
    # Check if there is mpv player present in current workspace, and if so
    # press 'Down' key to rewind back one minute
    CLASS="mpv"
    DESKTOP=$(xprop -notype -root _NET_CURRENT_DESKTOP | awk '{print $3}')
    xdotool search --desktop "$DESKTOP" --class "$CLASS" && xdotool key Down
    #xdotool getactivewindow getwindowname | grep -q "mpv" && xdotool key Down && echo "Pressed Down"

}

function videoPauseToggle {
    CLASS="mpv"
    DESKTOP=$(xprop -notype -root _NET_CURRENT_DESKTOP | awk '{print $3}')
    xdotool search --desktop "$DESKTOP" --class "$CLASS" && xdotool key space
    #xdotool getactivewindow getwindowname | grep -q "mpv" && xdotool key space && echo "Pressed space"
}

function reloadWebpage {
    CLASS="qutebrowser"
    DESKTOP=$(xprop -notype -root _NET_CURRENT_DESKTOP | awk '{print $3}')
    xdotool search --desktop "$DESKTOP" --class "$CLASS" && xdotool key F5
    #xdotool getactivewindow getwindowname | grep -q "qutebrowser" && \
    #    xdotool key F5
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
    # --pause           pause by default
    mpv --really-quiet --no-osd-bar --no-audio -fs --panscan=1.0 --loop-file \
        --pause "$FNAME" &
}

function openWebpage {
    FNAME="$1"

    URL="$(cat "$FNAME")"

    $BROWSER "$URL" &
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

    # Regex patterns for each file type
    IMAGE="(PNG|WEBP|JPEG|TIFF)"
    VIDEO="(MP4|WebM|Matroska|GIF)"
    WEBPAGE="(ASCII)"

    # Create new workspace for new file
    getNewWorkspace

    # Match file extensions via regex from 'file' command output to determine
    # how each file should be opened

    # Wait time in seconds. For example a web browser may take some time to
    # load. And we want to wait some time for them to load before proceeding
    # to open next file.
    # If application takes more time to load than the time specified as WAIT.
    # They may occupy the same workspace, which won't work in fullscreen apps.
    WAIT=10

    EXT="$(grep -oE "$IMAGE" <<<"$(file "${FILE}")")"
    [ -n "$EXT" ] && \
        { openImage "$FILE" && sleep $WAIT; return ; }

    EXT="$(grep -oE "$VIDEO" <<<"$(file "${FILE}")")"
    [ -n "$EXT" ] && \
        { openVideo "$FILE" && sleep $WAIT; return ; }

    EXT="$(grep -oE "$WEBPAGE" <<<"$(file "${FILE}")")"
    [ -n "$EXT" ] && \
        { openWebpage "$FILE" && sleep $WAIT; return ; }
}

function parseFiles {
    # Check that the specified direcotry exists and contain files
    [ ! -d "$FILESPATH" ] && \
        fatal "Directory defined in FILESPATH does not exist"

    # Check if files containing directory is empty
    [ -z "$(ls -A "$FILESPATH")" ] && \
        fatal "Directory specified in FILESPATH env varaible is empty"

    # Use 'find' command as for loop equivalent. Execute command for each file
    # found in files directory. Export needed functions first for them to be 
    # visible in new shell that the 'find' command creates
    export -f parseFile openImage openVideo openWebpage getNewWorkspace
    find "$FILESPATH" -type f -exec bash -c 'parseFile "$0"' {} \;
}
