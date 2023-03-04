#/bin/bash
#
# psstathelp.sh
# Help functions for pstat

function help_and_exit() {
    cat << EOF
Usage: psstat [OPTION] ...
List process information.
Options are
 --list-short                   list all processes in short format
 --list-long                    list all processes in long format 
 --list-name-has <name_part>    list all processes whose name has name_part in long format
 --list-pid-is <pid>            list status of process <pid>
 --list-sched-policy-is <policy_number>
    list all processes whose CPU scheduling policy number is <policy_number>
    in long format
EOF
}
