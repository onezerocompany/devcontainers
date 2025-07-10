#!/bin/bash

while getopts "h" opt; do
  case $opt in
    h)
      horizontal=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

charcount=0

function tool () {
  local tool="$1"
  local version_cmd=${2:-"--version"}
  local extract_version=${3:-"grep -o -m 1 '[0-9]*\.[0-9]*\.[0-9]*'"}

  if command -v $tool &> /dev/null;
  then
    local version=$(eval "$tool $version_cmd | $extract_version" | head -n 1) 
    if [ -z "$horizontal" ]; then
      printf "$tool\e[2m($version)\e[0m\n"
    else
      charcount+=#"$tool $version "
      if [ ${#charcount} -gt 80 ]; then
        printf "\n"
        charcount=0
      fi
      printf "$tool\e[2m($version)\e[0m "
    fi
  fi
}

tool "gh"
tool "git"
tool "starship"

tool "docker"

tool "bun"
tool "node" 
tool "npm"

tool "dart"
tool "flutter"
tool "pub"

tool "java"
tool "go" "version"
tool "rustc"
tool "cargo" 

tool "terraform" 
tool "tflint"
tool "terraform-docs"
tool "tf-summarize" "-v"

tool "kubectl" "version --client=true"
tool "helm" "version"

tool "python"
tool "pip"
tool "pipenv"

if [ ! -z "$horizontal" ]; then
  echo ""
fi