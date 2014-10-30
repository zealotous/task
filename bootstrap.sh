#!/usr/bin/env bash
REPO=https://github.com/zealotous/task.git

# клонируем репозиторий если в текущей папке нет run.sh
BOOTSTRAP="`pwd`/run.sh"
if [ ! -e $BOOTSTRAP ]; then
    git clone "$REPO"
    if [ $? -ne 0 ]; then
        echo "can't clone repo"
        exit 1
    fi
    cd task
    BOOTSTRAP="`pwd`/run.sh"
fi
