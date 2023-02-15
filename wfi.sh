#!/bin/bash

wfi() {
    WFI_LIST="${HOME}/.wfi"

    print_help() {
        echo "Wait For It"
        echo ""
        echo "Wait for process to stop, with a *beautiful* animation"
        echo ""
        echo "Usage:"
        echo "  wfi <pid> [<text>...]"
        echo "  wfi add <pid> [<text>...] [--start]"
        echo "  wfi bulk <pid> [<pid>...] [--start]"
        echo "  wfi list"
        echo "  wfi start"
        echo "  wfi clear"
        echo ""
        echo "Options:"
        echo "  <pid>        PID of the process to wait for"
        echo "  <text>       Name of the process"
        echo "  add          Add an entry to the queue"
        echo "  bulk         Add multiple entries to the queue"
        echo "  list         List entries of the queue"
        echo "  start        Start the execution of the queue"
        echo "  clear        Clear the queue"
        echo "  -h, --help   Display this help"
        echo "  -s, --start  When adding a process, start the animation immediately"
        echo ""
        echo "The PID of the last command can be obtained with the \$! bash keyword."
        echo "When <text> is missing, the program will try to retrieve the command line from"
        echo "the operating system."
        echo ""
        echo "wfi can be disrupted by other programs stdout. To prevent this the best way is"
        echo "to redirect all output to a log file, or /dev/null"
        echo ""
        echo "    $ sleep 25 &> log.txt &"
        echo "    $ wfi \$! Sleeping for 25 seconds"
        echo ""
        echo "wfi is also usable as a queue, to follow the progress of multiple processes"
        echo ""
        echo "    $ sleep 20 &> /dev/null &"
        echo "    $ wfi add \$!"
        echo "    $ sleep 5 &> /dev/null &"
        echo "    $ wfi add \$!"
        echo "    $ wfi start"
        echo ""
        echo "The intended use of the 'bulk' mode is in conjonction with the 'jobs' command"
        echo ""
        echo "    $ sleep 20 &> /dev/null &"
        echo "    $ sleep 5 &> /dev/null &"
        echo "    $ wfi bulk \$(jobs -p)"
        echo "    $ wfi start"
        echo ""
    }

    _add() {
        pid=$1
        text=${@:2}
        echo "${pid} ${text}" >> $WFI_LIST
    }

    _start() {
        if [[ ! -e $WFI_LIST ]]; then
            echo "No queue to start"
            return 1
        fi

        declare -A pids
        while read line; do
            pid=$(echo $line | cut -d ' ' -f 1)
            text=$(echo $line | cut -s -d ' ' -f 2-)
            if [[ $text == "" ]]; then
                text=$(ps -p $pid -o command=)
            fi
            pids[$pid]=$text
        done < $WFI_LIST

        iter=0

        # When the function exits, the command will be executed to
        # reset the cursor visibility. Equivalent to a try..catch
        trap "tput cnorm && trap RETURN && trap SIGINT" RETURN SIGINT

        # hide cursor
        tput civis

        until _alldead "${!pids[@]}"; do
            for pid in "${!pids[@]}"; do
                _printline $pid "${pids[$pid]}" $iter
            done

            sleep 0.125

            iter=$((iter+1))
            ((iter==${#spinner})) && iter=0

            # Go back one line for each
            for pid in "${!pids[@]}"; do
                tput cuu1
            done
        done
        for pid in "${!pids[@]}"; do
            _printline $pid "${pids[$pid]}" $iter
        done
        return
    }

    _list() {
        if [[ ! -e $WFI_LIST ]]; then
            echo "No queue"
            return 1
        fi

        while read line; do
            pid=$(echo $line | cut -d ' ' -f 1)
            text=$(echo $line | cut -s -d ' ' -f 2-)
            echo "  ${pid} : ${text}"
        done < $WFI_LIST
    }

    _clear() {
        rm -f $WFI_LIST
    }

    spinner='/-\|'

    _printline () {

        pid=$1
        name=$2
        iter=$3

        dash=$(printf ".%.0s" $(seq ${#name} 71))

        _isdead $pid
        if [[ $? -eq 1 ]]; then
            echo "${name} ${dash} ${spinner:iter:1}     "
        else
            wait $pid
            if [[ $? -ne 0 ]]; then
                res="[ \033[91mKO\033[0m ]"
            else
                res="[ \033[92mOK\033[0m ]"
            fi

            echo -e "${name} ${dash} ${res}"
        fi
    }

    _isdead() {
        kill -0 $1 2&> /dev/null
        [ $? -ne 0 ]
    }

    _alldead() {
        ps -hp $* &> /dev/null
        [ $? -eq 1 ]
    }

    if [[ $# -lt 1 ]]; then
        print_help
        return 1
    fi

    POSITIONAL_ARGS=()
    queue=no
    start=0
    while [[ $# -gt 0 ]]; do
        case $1 in
            add|list|clear|start|bulk)
                queue=$1
                shift
                ;;
            -s|--start)
                start=1
                shift
                ;;
            -h|--help)
                print_help
                return 1
                ;;
            *)
                POSITIONAL_ARGS+=("$1") # save positional arg
                shift
                ;;
        esac
    done

    set -- "${POSITIONAL_ARGS[@]}"

    pid=$1
    text=${@:2}

    if [[ "${queue}" == "no" ]]; then
        _clear
        _add $pid $text
        _start
        _clear
    elif [[ "${queue}" == "add" ]]; then
        _add $pid $text
        if [[ $start -eq 1 ]]; then
            _start
            _clear
        fi
    elif [[ "${queue}" == "start" ]]; then
        _start
        _clear
    elif [[ "${queue}" == "list" ]]; then
        _list
    elif [[ "${queue}" == "clear" ]]; then
        _clear
    elif [[ "${queue}" == "bulk" ]]; then
        for p in $*; do
            _add $p
        done
        if [[ $start -eq 1 ]]; then
            _start
            _clear
        fi
    fi
}

export -f wfi