#!/bin/bash

# Generate MOTD with colored banner
cat << 'EOF'

 ██████╗ ███╗   ██╗███████╗███████╗███████╗██████╗  ██████╗ 
██╔═══██╗████╗  ██║██╔════╝╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
██║   ██║██╔██╗ ██║█████╗    ███╔╝ █████╗  ██████╔╝██║   ██║
██║   ██║██║╚██╗██║██╔══╝   ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
╚██████╔╝██║ ╚████║███████╗███████╗███████╗██║  ██║╚██████╔╝
 ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝

This is a OneZero Company development container

Run 'tools' to see installed development tools
Run 'mise ls-remote' to see available tools
EOF