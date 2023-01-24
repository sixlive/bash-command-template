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
colorOutput() {
    local color="$1"
    local content="$2"

    # Color mappings
    local default="\033[0m"
    local red="\033[31m"
    local green="\033[0;32m"
    local yellow="\033[0;33m"
    local cyan="\033[0;35m"
    local magenta="\033[0;36m"


    printf "${!color}$content$default"
}

printDefault () {
    colorOutput "default" "$1\r\n"
}

printInfo() {
    colorOutput "cyan" "$1\r\n"
}

printCaution() {
    colorOutput "yellow" "$1\r\n"
}

printSuccess() {
    colorOutput "green" "$1\r\n"
}

printError() {
    colorOutput "red" "$1\r\n" >&2
}

printSection () {
    local divider;
    divider="------------------------------------------------------------"

    printInfo $divider
    printDefault "$1"
    printInfo $divider 
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

    question+=" [$confirmPrompt] "

    colorOutput "magenta" "$question " 

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
        echo -en "\033[$1D"
    }

    function spin() {
        local LC_CTYPE=C

        local pid=$2
        local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
        local charwidth=3
        local i=0
        local label="$1"

        tput civis # cursor invisible
        while kill -0 $pid 2>/dev/null; do
            local i=$(((i + $charwidth) % ${#spin}))
            colorOutput "cyan" "${spin:$i:$charwidth} $label"


            cursorBack $((${#label} + 2))
            sleep .1
        done

        tput cnorm
        wait $pid

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
    printf "\r\n"
    printSuccess "Party cleanup complete!"
}

# Main function that is called when the script executes
main() {
    trap cleanup EXIT

    printSection "Party Time 🎉"

    local confirmation
    confirm confirmation "Are you ready to party?" "yes/NO" "(yes)"

    if ! $confirmation; then
        printError "Party cancelled 😢"
        exit 1
    fi

    spinner "Getting the party ready" sleep 2
    printSuccess "LEEEEEEETS GOOOOOOOOOO 🥳"
}

main "$@"
