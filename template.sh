#!/usr/bin/env bash

# Setup
# ---------------------------------------------------------------
set -o errexit
set -o nounset
set -o pipefail

trap cleanup SIGINT SIGTERM ERR EXIT

if [[ -n "${TRACE-}" ]]; then
    set -o xtrace
fi

# Utilities
# ---------------------------------------------------------------

# Print a message to stdout
# Usage: prntc <color> <message>
# Example: prntc "red" "This is a red message"
prntc() {
    local color="$1"
    local content="${2:-}"

    # Color mappings
    local default="\033[0m"
    local red="\033[31m"
    local green="\033[0;32m"
    local yellow="\033[0;33m"
    local magenta="\033[0;35m"
    local cyan="\033[0;36m"

    if [[ -z "${!color-}" ]]; then
        content="$color"
        color="default"
    fi

    printf "${!color}$content$default"
}

# Print a message to stdout with a newline
# Usage: prntcn <color> <message>
# Example: prntcn "red" "This is a red message"
prntcn() {
    local color="$1"
    local content="${2:-}"

    printf "$(prntc "$color" "$content") \r\n"
}

# Print a message to stdout with a newline
# Usage: prntTitle <message>
# Example: prntTitle "This is a title"
prntTitle () {
    prntDivider
    prntcn "$1"
    prntDivider
}

# Print a divider
# Usage: prntDivider <message>
# Example: prntDivider "This is a divider"
# Example: prntDivider
prntDivider () {
    local divider;
    local content="${1:-}"
    divider=$(printf -- '-%.0s' {1..60})

    # if content is empty then just print the divider
    if [[ -z "$content" ]]; then
        prntcn "cyan" "$divider"
        return
    fi

    local contentLength=${#content}
    local dividerLength=${#divider}
    
    if [[ "$contentLength" -gt "$dividerLength" ]]; then
        prntcn "red" "Content is longer than the divider"
        exit 1
    fi

    content="-- $content "

    local diff=$((dividerLength - ${#content}))

    printf "\r\n"
    prntc "cyan" "$content"
    prntcn "cyan" "${divider:0:$diff}"
}

# Prompt the user to confirm
#
# @param  variable  The to assign the result to
# @param  string  The question to prompt the user with
# @param  string  The prompt to show the user
# @param  string  The regex to match the response against
#
# Example:
#  confirm confirmation "Are you sure?" "yes/NO" "(yes)"
confirm() {
    local confirmExport="$1"
    local export=false
    local question="${2:-"Are you sure?"}"
    local confirmPrompt="${3:-"y/N"}"
    local confirmMatcher="${4:-"(y)"}"

    question+=$(prntc "cyan" " [$confirmPrompt] ")

    prntc "magenta" "$question "

    # read response
    response=$(read -e line; echo "$line")

    shopt -s nocasematch

    if [[ $response =~ $confirmMatcher ]]; then
        export=true
    else
        export=false
    fi

    shopt -u nocasematch

    eval "$confirmExport=$export"
}

# Show a spinner while running a command
# @param  string  The label to show next to the spinner
# @param  string  The command to run
#
# Example:
#   spinner "Pinging google" ping -c 3 google.com
spinner () {
    function shutdown() {
        tput cnorm # reset cursor
    }

    trap shutdown EXIT

    function cursorBack() {
        printf "\r"; printf ' %0.s' {0..20}
    }

    function spin() {
        local LC_CTYPE=C

        local pid=$2
        local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
        local charwidth=3
        local i=0
        local label="$1"
        local length=(${#label} + $charwidth + 1)

        tput civis # cursor invisible
        while kill -0 $pid 2>/dev/null; do
            local i=$(((i + $charwidth) % ${#spin}))
            prntc "cyan" "${spin:$i:$charwidth} $label"
            printf "\r";
            printf '%0.s' {0..$length}

            sleep .1
        done

        tput cnorm
        wait $pid

        prntcn "cyan" "✓ $label"

        return $?
    }

    ("${@:2}") >/dev/null &

    spin "$1" $!
}

# App Code
# ---------------------------------------------------------------

# This method is referenced in the trap above
cleanup () {
    trap - SIGINT SIGTERM ERR EXIT
    printf "\r\n" # ensure we have a new line if an error occured

    prntDivider "Cleanup"
    prntcn "green" "Done!"
}

# Parse the command line arguments
# Usage: parseArgs "$@"
# Example: parseArgs "$@"
parseArgs() {
    while getopts i:o: flag; do
        case "${flag}" in
            i) 
                input="${OPTARG}"
                ;;
            o) 
                output="${OPTARG}"
                ;;
        esac
    done
}

# Main function that is called when the script executes
main() {
    prntTitle "Party Time 🎉"

    parseArgs "$@"
    prntDivider "Args"
    prntc "magenta" "Input Arg: "
    prntcn "cyan" "${input:-"No input provided"}"
    prntc "magenta" "Output Arg: "
    prntcn "cyan" "${output-"No input provided"}"

    prntDivider "Party pre-game"

    local confirmation
    confirm confirmation "Are you ready to party?" "yes/NO" "(yes)"

    if ! $confirmation; then
        prntcn "red" "Party cancelled 😢"
        exit 1
    fi

    spinner "Getting the party ready" sleep 2
    prntcn "green" "LEEEEEEETS GOOOOOOOOOO 🥳"

    cleanup
}

main "$@"
