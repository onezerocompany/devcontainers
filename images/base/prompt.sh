name() {
  local dir=$(pwd)
  local name=${PROJECT_NAME:-"@$(whoami)"}
  local home=$(echo $HOME)
  if [[ -n $PROJECT_DIR && $dir == $PROJECT_DIR ]]; then
    echo "$name"
  elif [[ -n $PROJECT_DIR && $dir == $PROJECT_DIR* ]]; then
    echo "$name "
  elif [[ $dir == $home ]]; then
    echo "$name"
  elif [[ $dir == $home* ]]; then
    echo "$name "
  else
    echo ""
  fi
}

directory() {
  local dir=$(pwd)
  local home=$(echo $HOME)
  if [[ -n $PROJECT_DIR && $dir == $PROJECT_DIR* ]]; then
    echo ${dir#$PROJECT_DIR}
  elif [[ $dir == $home* ]]; then
    echo ${dir#$home}
  else
    echo $dir
  fi
}

PROMPT='%F{green}$(name)%f%F{cyan}$(directory)%f → '