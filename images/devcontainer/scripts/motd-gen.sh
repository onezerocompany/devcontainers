#!/bin/bash

# Simple colored banner
BANNER="\033[35m ██████╗ ███╗   ██╗███████╗███████╗███████╗██████╗  ██████╗ 
██╔═══██╗████╗  ██║██╔════╝╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
██║   ██║██╔██╗ ██║█████╗    ███╔╝ █████╗  ██████╔╝██║   ██║
██║   ██║██║╚██╗██║██╔══╝   ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
╚██████╔╝██║ ╚████║███████╗███████╗███████╗██║  ██║╚██████╔╝
 ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝\033[0m"

printf "\n$BANNER\n"
# reset colors and styles
printf "\033[0m"
printf "\nThis is a OneZero Company development container\n"
printf "\nRun 'tools' to see installed development tools\n"
printf "Run 'mise ls-remote' to see available tools\n"