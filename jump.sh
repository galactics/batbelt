##################################################################
# mark/jump
##################################################################

export MARKPATH=$HOME/.marks
function jump {
    cd -P $MARKPATH/$1 2>/dev/null || echo "No such mark: $1"
}
function mark {
    mkdir -p $MARKPATH; ln -s $(pwd) $MARKPATH/$1
}
function unmark {
    rm -i $MARKPATH/$1
}
function marks {

    while [[ $# -gt 0 ]]; do
      case $1 in
        -e|--export)
          case=export
          shift
          ;;
        -i|--import)
          case=import
          filepath=$2
          shift
          shift
          ;;
        -h|--help)
          echo "Marks"
          echo ""
          echo "Usage:"
          echo "  marks [--export] [--import <file>] [--help]"
          echo "Options:"
          echo "  --export             Export a text format of the current state"
          echo "  --import <filepath>  Create all links"
          echo "  --help               Display this help"
          echo ""
          echo "If no option is provided, the program display the current"
          echo "state in an user-friendly form"
          return 1
      esac
    done

    IFS=$'\n'
    filelist=$(ls -l --color=never $MARKPATH | sed 's/  / /g' | cut -d' ' -f9-)

    if [[ "${case}" == "export" ]]; then
        for f in $filelist; do
            name=$(echo $f | cut -d ' ' -f 1)
            path=$(echo $f | cut -d ' ' -f 3)
            printf "%s %s\n" $name $path
        done
        return 0
    elif [[ "${case}" == "import" ]]; then
        echo "Importing $filepath"
        mkdir -p $MARKPATH
        while read line; do
            name=$(echo $line | cut -d ' ' -f 1)
            path=$(echo $line | cut -d ' ' -f 2)
            if [ -L $MARKPATH/$name ]; then
                echo "link '$name' already exists"
            else
                ln -s $path $MARKPATH/$name
                echo "creating '$name' at '$path'"
            fi
        done < $filepath
    else
        # Find the largest folder name
        max=0
        for i in ${filelist[@]}; do 
            name=$(echo $i | cut -d ' ' -f 1)
            (( ${#name} > max )) && max=${#name}
        done

        for f in $filelist; do
            name=$(echo $f | cut -d ' ' -f 1)
            path=$(echo $f | cut -d ' ' -f 3)
            printf " \033[1m\033[96m% *s\033[0m  %s\n" $max $name $path
        done
    fi
}

function _jump {
    cur="${COMP_WORDS[COMP_CWORD]}"
    opts=$(ls -1 --color=never $MARKPATH)
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _jump jump