#!/bin/zsh

USER=${1:-"runner"}
USER_ID=${2:-"1000"}
GROUP_ID=${3:-"1000"}

# Create group
groupadd -g $GROUP_ID $USER && echo "Group $USER created"

# Create user
useradd -m -u $USER_ID -g $GROUP_ID -s /bin/zsh $USER && echo "User $USER created"

# Give sudo powers
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set password to same as username
echo $USER | chpasswd

# Set user as owner of home directory
chown -R $USER:$USER /home/$USER