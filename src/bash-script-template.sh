#! /usr/bin/env bash

# -------------------------------------------------------------------------------- #
# Description                                                                      #
# -------------------------------------------------------------------------------- #
# This is a simple bash script wrapper designed to allow you to quickly create     #
# scripts in a standard way.                                                       #
#                                                                                  #
# Key features:                                                                    #
#     Strict mode (Optional)                                                       #
#     Root user detection (Optional)                                               #
#     Prerequisite checker                                                         #
#     cli processing                                                               #
#     Wrapper functions                                                            #
#     Colour handling (optional)                                                   #
#     Rollback handling (Deterministic)                                            #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Rollback Stack                                                                   #
# -------------------------------------------------------------------------------- #
# This is the list of functions that should be called in the event of a rollback.  #
# -------------------------------------------------------------------------------- #

rollback_stack=( )

# -------------------------------------------------------------------------------- #
# Required commands                                                                #
# -------------------------------------------------------------------------------- #
# These commands MUST exist in order for the script to correctly run.              #
# -------------------------------------------------------------------------------- #

PREREQ_COMMANDS=( )

# -------------------------------------------------------------------------------- #
# Flags                                                                            #
# -------------------------------------------------------------------------------- #
# A set of global flags that we use for configuration.                             #
# -------------------------------------------------------------------------------- #

STRICT_MODE=true                 # Should we run in strict mode?
VERBOSE=false                    # Should we give verbose output ?
ALLOW_ZERO_INPUT=true            # Do we require any user input ?
USE_COLOURS=true                 # Should we use colours in our output ?
FORCE_TERMINAL=true              # Force terminal type if requied
TERMINAL_TYPE=xterm              # What terminal should we force?
ROOT_ONLY=false                  # Should the script be run only by the root user ?
READONLY_INFO=true               # Set the script info to READONLY

# -------------------------------------------------------------------------------- #
# Variables                                                                        #
# -------------------------------------------------------------------------------- #
# A set of global variables.                                                       #
# -------------------------------------------------------------------------------- #

#
# Variables go here if required
#

# -------------------------------------------------------------------------------- #
# The wrapper function                                                             #
# -------------------------------------------------------------------------------- #
# This is where you code goes and is effectively your main() function.             #
# -------------------------------------------------------------------------------- #

function wrapper()
{
    echo "${fgGreen}I got here!!${reset}"
}

# -------------------------------------------------------------------------------- #
# Usage (-h parameter)                                                             #
# -------------------------------------------------------------------------------- #
# This function is used to show the user 'how' to use the script.                  #
# -------------------------------------------------------------------------------- #

function usage()
{
    [[ -n "${*}" ]] && error "  Error: ${*}"

cat <<EOF
  Usage: $0 [ -hdv ] [ -f ] [ -p value ]
    -h | --help      : Print this screen
    -d | --debug     : Turn on debug mode (set -o xtrace)
    -v | --verbose   : Verbose output
    -f | --flag      : flag with no parameter
    -p | --parameter : With parameter
EOF
    clean_exit 1;
}

# -------------------------------------------------------------------------------- #
# Test Getopt                                                                      #
# -------------------------------------------------------------------------------- #
# Test to ensure we have the GNU getopt available.                                 #
# -------------------------------------------------------------------------------- #

function test_getopt
{
    if getopt --test > /dev/null && true; then
        error "'getopt --test' failed in this environment - Please ensure you are using the gnu getopt."
        if [[ "$(uname -s || true)" == "Darwin" ]]; then
            error "You are using MAcOS - please ensure you have installed gnu-getopt and updated your path."
        fi
        clean_exit 1
    fi
}

# -------------------------------------------------------------------------------- #
# Process Arguments                                                                #
# -------------------------------------------------------------------------------- #
# This function will process the input from the command line and work out what it  #
# is that the user wants to do.                                                    #
#                                                                                  #
# This is the main processing function where all the processing logic is handled.  #
# -------------------------------------------------------------------------------- #

function process_arguments()
{
    local options
    local longopts
    local error_msg

    if [[ "${ALLOW_ZERO_INPUT}" = false ]] && [[ $# -eq 0 ]]; then
        usage
    fi

    test_getopt

    options=hdvfp:
    longopts=help,debug,verbose,flag,parameter:

    if ! PARSED=$(getopt --options="${options}" --longoptions="${longopts}" --name "$0" -- "$@" 2>&1) && true; then
        error_msg=$(echo -e "${PARSED}" | head -n 1 | awk -F ':' '{print $2}')
        usage "${error_msg}"
    fi
    eval set -- "${PARSED}"
    while true; do
        case "${1}" in
            -h|--help)
                usage
                ;;
            -d|--debug)
                set -o xtrace     # [set -x]
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--flag)
                echo "Flag Set"
                shift
                ;;
            -p|--parameter)
                echo "-p $2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Default"
                ;;
        esac
    done

    wrapper
    clean_exit
}

# -------------------------------------------------------------------------------- #
# STOP HERE!                                                                       #
# -------------------------------------------------------------------------------- #
# The functions below are part of the template and should not require any changes  #
# in order to make use of this template. If you are going to edit code beyound     #
# this point please ensure you fully understand the impact of those changes!       #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Utiltity Functions                                                               #
# -------------------------------------------------------------------------------- #
# The following functions are all utility functions used within the script but are #
# not specific to the display of the colours and only serve to handle things like, #
# signal handling, user interface and command line option processing.              #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Init Colours                                                                     #
# -------------------------------------------------------------------------------- #
# This function will check to see if we are able to support colours and how many   #
# we are able to support.                                                          #
#                                                                                  #
# Variables intentionally not defined 'local' as we want them to be global.        #
# -------------------------------------------------------------------------------- #

function init_colours()
{
    local ncolors

    fgRed=''
    fgGreen=''
    fgYellow=''
    fgCyan=''
    bold=''
    reset=''

    if [[ "${USE_COLOURS}" = false ]]; then
        return
    fi

    if ! test -t 1; then
        if [[ "${FORCE_TERMINAL}" = true ]]; then
            export TERM=${TERMINAL_TYPE}
        else
            return
        fi
    fi

    if ! tput longname > /dev/null 2>&1; then
        return
    fi

    ncolors=$(tput colors)

    if ! test -n "${ncolors}" || test "${ncolors}" -le 7; then
        return
    fi

    fgRed=$(tput setaf 1)
    fgGreen=$(tput setaf 2)
    fgYellow=$(tput setaf 3)
    fgCyan=$(tput setaf 6)

    bold=$(tput bold)
    reset=$(tput sgr0)
}

# -------------------------------------------------------------------------------- #
# Error                                                                            #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to show something was an error.                        #
# -------------------------------------------------------------------------------- #

function error()
{
    # shellcheck disable=SC2317
    notify 'error' "${@}"
}

# -------------------------------------------------------------------------------- #
# Warning                                                                          #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to show something was a warning.                       #
# -------------------------------------------------------------------------------- #

function warn()
{
    # shellcheck disable=SC2317
    notify 'warning' "${@}"
}

# -------------------------------------------------------------------------------- #
# Success                                                                          #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to show something was a success.                       #
# -------------------------------------------------------------------------------- #

function success()
{
    # shellcheck disable=SC2317
    notify 'success' "${@}"
}

# -------------------------------------------------------------------------------- #
# Info                                                                             #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to show something is information.                      #
# -------------------------------------------------------------------------------- #

function info()
{
    # shellcheck disable=SC2317
    notify 'info' "${@}"
}

# -------------------------------------------------------------------------------- #
# Notify                                                                           #
# -------------------------------------------------------------------------------- #
# Handle all types of notification in one place.                                   #
# -------------------------------------------------------------------------------- #

function notify()
{
    local type="${1:-}"
    shift
    local message="${*:-}"
    local fgColor

    if [[ -n ${message} ]]; then
        case "${type}" in
            error)
                fgColor="${fgRed}";
                ;;
            warning)
                fgColor="${fgYellow}";
                ;;
            success)
                fgColor="${fgGreen}";
                ;;
            info)
                fgColor="${fgCyan}";
                ;;
            *)
                fgColor='';
                ;;
        esac
        printf '%s%b%s\n' "${fgColor}${bold}" "${message}" "${reset}" 1>&2
    fi
}

# -------------------------------------------------------------------------------- #
# Check Prerequisites                                                              #
# -------------------------------------------------------------------------------- #
# Check to ensure that the prerequisite commmands exist.                           #
# -------------------------------------------------------------------------------- #

function check_prereqs()
{
    local error_count=0

    for i in "${PREREQ_COMMANDS[@]}"
    do
        command=$(command -v "${i}" || true)
        if [[ -z ${command} ]]; then
            warn "${i} is not in your command path"
            error_count=$((error_count+1))
        fi
    done

    if [[ ${error_count} -gt 0 ]]; then
        error "${error_count} errors located - fix before re-running";
        clean_exit 1;
    fi
}

# -------------------------------------------------------------------------------- #
# Check Root                                                                       #
# -------------------------------------------------------------------------------- #
# If required ensure the script is running as the root user.                       #
# -------------------------------------------------------------------------------- #

function check_root()
{
    (( EUID != 0 )) && clean_exit 1 "This script must be run as root"
}

# -------------------------------------------------------------------------------- #
# Clean Exit                                                                       #
# -------------------------------------------------------------------------------- #
# Unset the traps and exit cleanly, with an optional exit code / message.          #
# -------------------------------------------------------------------------------- #

function clean_exit()
{
    unset_traps

    [[ -n ${2:-} ]] &&  error "${2}"
    exit "${1:-0}"
}

# -------------------------------------------------------------------------------- #
# Add Rollback                                                                     #
# -------------------------------------------------------------------------------- #
# Add a rollback function to the stack.                                            #
# -------------------------------------------------------------------------------- #

function add_rollback()
{
    # shellcheck disable=SC2317
    rollback_stack[${#rollback_stack[*]}]=$1;
}

# -------------------------------------------------------------------------------- #
# Run Rollback                                                                     #
# -------------------------------------------------------------------------------- #
# Run all of the rollback function.                                                #
#                                                                                  #
# It is important to understand that rollbacks are run in the opposite order to    #
# which they are added as the rollback is a 'stack' [aka a LIFO].                  #
#                                                                                  #
# It is 'important' to unset the traps before running the rollback otherwise       #
# errors in the rollback code could trigger another rollback and a possible loop.  #
# -------------------------------------------------------------------------------- #

# shellcheck disable=SC2317
function run_rollbacks()
{
    unset_traps

    [[ "${VERBOSE}" = true ]] && printf '\nTrap Triggers - Running Rollbacks\n\n'

    while [[ ${#rollback_stack[@]} -ge 1 ]]; do
        ${rollback_stack[${#rollback_stack[@]}-1]} rollback;
        unset "rollback_stack[${#rollback_stack[@]}-1]";
    done

    clean_exit 1 "Rollback was run"
}

# -------------------------------------------------------------------------------- #
# Set Traps                                                                        #
# -------------------------------------------------------------------------------- #
# We only want the rollbacks to run on error - so we set up traps to catch the     #
# errors and handle the rollbacks.                                                 #
# -------------------------------------------------------------------------------- #

function set_traps()
{
    trap run_rollbacks INT TERM EXIT
}

# -------------------------------------------------------------------------------- #
# Unset Traps                                                                      #
# -------------------------------------------------------------------------------- #
# Once everything has run cleanly we want to reset the traps, otherwise exiting    #
# the script will cause the rollbacks to run undoing all the scripts good work.    #
# -------------------------------------------------------------------------------- #

function unset_traps()
{
    trap - INT TERM EXIT
}

# -------------------------------------------------------------------------------- #
# Enable strict mode                                                               #
# -------------------------------------------------------------------------------- #
# errexit = Any expression that exits with a non-zero exit code terminates         #
# execution of the script, and the exit code of the expression becomes the exit    #
# code of the script.                                                              #
#                                                                                  #
# pipefail = This setting prevents errors in a pipeline from being masked. If any  #
# command in a pipeline fails, that return code will be used as the return code of #
# the whole pipeline. By default, the pipeline's return code is that of the last   #
# command - even if it succeeds.                                                   #
#                                                                                  #
# noclobber = Prevents files from being overwritten when redirected (>|).          #
#                                                                                  #
# nounset = Any reference to any variable that hasn't previously defined, with the #
# exceptions of $* and $@ is an error, and causes the program to immediately exit. #
# -------------------------------------------------------------------------------- #

function set_strict_mode()
{
    set -o errexit -o noclobber -o nounset -o pipefail
    IFS=$'\n\t'
}

# -------------------------------------------------------------------------------- #
# Get Script Info                                                                  #
# -------------------------------------------------------------------------------- #
# Work out some basic facts about the script, how it was called, where it lives,   #
# what it is called etc.                                                           #
# -------------------------------------------------------------------------------- #

function get_script_info()
{
    local ro=${READONLY_INFO:-false}

    [[ $0 != "${BASH_SOURCE[0]}" ]] && IS_SOURCED=true || IS_SOURCED=false

    INVOKED_FILE="${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}"
    INVOKED_PATH="$(dirname "${BASH_SOURCE[${#BASH_SOURCE[@]} - 1]}")"
    FULL_PATH="$( cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
    FILE_NAME=$(basename "${BASH_SOURCE[0]}")

    if [[ $# -gt 0 ]]; then
        SCRIPT_ARGS=$(printf "'%s', " "${@}")
        SCRIPT_ARGS=${SCRIPT_ARGS::-2}                # Trim off the last comma and space
    else
        SCRIPT_ARGS="None"
    fi

    if [[ "${ro}" = true ]]
    then
        readonly IS_SOURCED
        readonly INVOKED_FILE
        readonly INVOKED_PATH
        readonly FULL_PATH
        readonly FILE_NAME
        readonly SCRIPT_ARGS
    fi

    export IS_SOURCED
    export INVOKED_FILE
    export INVOKED_PATH
    export FULL_PATH
    export FILE_NAME
    export SCRIPT_ARGS
}

# -------------------------------------------------------------------------------- #
# Main()                                                                           #
# -------------------------------------------------------------------------------- #
# The main function where all of the heavy lifting and script config is done.      #
# -------------------------------------------------------------------------------- #

function main()
{
    init_colours

    [[ "${STRICT_MODE}" = true ]] && set_strict_mode

    [[ "${ROOT_ONLY}" = true ]] && check_root

    set_traps
    get_script_info "${@}"
    check_prereqs
    process_arguments "${@}"
}

# -------------------------------------------------------------------------------- #
# Main()                                                                           #
# -------------------------------------------------------------------------------- #
# This is the actual 'script' and the functions/sub routines are called in order.  #
# -------------------------------------------------------------------------------- #

main "${@}"

# -------------------------------------------------------------------------------- #
# End of Script                                                                    #
# -------------------------------------------------------------------------------- #
# This is the end - nothing more to see here.                                      #
# -------------------------------------------------------------------------------- #
