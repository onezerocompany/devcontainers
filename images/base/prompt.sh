#!/bin/zsh

PROJECT_NAME=${PROJECT_NAME:-"home"}
PROMPT_BASE_DIR=${PROMPT_BASE_DIR:-$HOME}
CURRENT_DIR=$(pwd)

PROMPT=""

name () {
  echo -e "\033[0;32m$1\033[0m"
}

path () {  
  echo -e "\033[0;36m$1\033[0m"
}

cursor () {
  echo -e "\033[2m$1\033[0m"
}

if [[ $CURRENT_DIR == $PROMPT_BASE_DIR* ]]; then
  PROMPT+=$(name $PROJECT_NAME)

  # if the current directory is not the base directory
  if [[ $CURRENT_DIR != $PROMPT_BASE_DIR ]]; then
    PROMPT+=" $(path ${CURRENT_DIR#$PROMPT_BASE_DIR})"
  fi
else
  PROMPT+=$(path $CURRENT_DIR)
fi

PROMPT+=" $(cursor →) "