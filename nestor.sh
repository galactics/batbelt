function nestor() {
    # Nestor    
    # Notify you when a task is completed
    #
    # Usage:
    #     nestor <command>...
    #     <command>... ; nestor

    cmd=$*

    if [[ -n $cmd ]]; then
        eval $cmd
        code=$?
        notify-send -u critical "nestor" "${cmd}\nfinished (${code})"
    else
        notify-send -u critical "nestor" "job finished"
    fi
}