#!/bin/bash

function list_short() {
    ls /proc | egrep '[0-9]+' | sort -n | column
}

# function old_list_long() {
#     for pid in $(list_short); do
#         echo -n "$pid,"
#         cat -s "/proc/$pid/comm" | tr '\n' ','
#         perl -ne '/[0-9]+ (?:\(.*?\)|.*?) (.*?) /; print "$1,";' "/proc/$pid/stat"
#         awk -F \0 '{printf $0}' /proc/$pid/cmdline
#         echo ""
#     done | column -t -s , -l 4 -T 4
# }

stat_read='BEGIN { FPAT = "\(([^\)])\)" } {patsplit($0, FPAT, FIELDS); print(FIELDS[1])} END {}'

# more efficient version that uses fewer piped processes
function list_long()
{
    for pid in $(ls /proc | egrep '[0-9]+' | sort -n); do
        comm="$(</proc/$pid/comm)"
        stat=$(perl -ne '/[0-9]+ (?:\(.*?\)|.*?) (.*?) /; print "$1";' "/proc/$pid/stat")
        cmdline=$(cat "/proc/$pid/cmdline" | tr '\0' ' ' | tr ';' ',')
        if [ -n "$cmdline" ]; then
            cmdline=${cmdline::-1}
        fi
        printf '%d;"%s";%s;"%s"\n' "$pid" "$comm" "$stat" "$cmdline"
    done | column -t -s \; -l 4 -W 4 -N PID,CMD,ST,CMD_ARGS
}


function list_long_2() {
    # loop through all processes in /proc and write
    # comma-separated fields to STDOUT
    for pid in $(ls /proc | egrep '[0-9]+' | sort -n); do
        echo -n "$pid,"
        # COMMAND
        #   awk lets us strip the trailing newline and add the quotes
        #   and comma delimiter with one command
        awk '{printf "\""$1"\","}' "/proc/$pid/comm"
        # STATUS
        #   perl makes it easy to reference sub-expression of regex in a
        #   one-liner
        perl -ne '/[0-9]+ (?:\(.*?\)|.*?) (.*?) /; print "$1,";' "/proc/$pid/stat"
        # CMDLINE
        #   cmdline is in a NULL delimited string, which we can convert
        #   to space-delimited with tr.
        #   We only have to worry about stripping the ugly trailing
        #   space and adding the quotes when the cmdline field is
        #   non-empty
        cmdline=$(cat /proc/$pid/cmdline | tr '\0' ' ')
        if [ -n "$cmdline" ]; then
            cmdline=${cmdline::-1}
            echo '"'"$cmdline"'"'
        fi
    done | column -t -s , -l 4 -W 4 -N PID,CMD,ST,CMD_ARGS
    # standard output can be piped through column for pretty printed
    # output. switch -W to -T to truncate the long cmdline column
    # instead of wrapping it in a multi-line cell.
}
