#!/bin/bash
# Create a user with the specified name or default to 'zero'
# Usage: create-user.sh [username] [user_id] [group_id] [passwordless_sudo]

USER=${1:-${USERNAME:-zero}}
USER_ID=${2:-${USER_UID:-1000}}
USER_GROUP=${3:-${USER_GID:-1000}}
PASSWORDLESS_SUDO=${4:-${PASSWORDLESS_SUDO:-false}}

HOME=/home/$USER

echo "Creating user '$USER' (UID=$USER_ID, GID=$USER_GROUP)..."

# Check if the user already exists
if id "$USER" &>/dev/null; then
    echo "User '$USER' already exists."
    exit 1
fi

# Check if the group exists, otherwise create it
if ! getent group "$USER_GROUP" &>/dev/null; then
    groupadd -g "$USER_GROUP" "$USER"
fi

# Create the user
useradd --uid "$USER_ID" --gid "$USER_GROUP" -m -s /bin/bash "$USER"
echo "Created user '$USER'"

# Setup passwordless sudo (if requested)
if [ "$PASSWORDLESS_SUDO" = true ]; then
    mkdir -p /etc/sudoers.d
    echo "$USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER"
    chmod 0440 "/etc/sudoers.d/$USER"
fi

# Create the user's directories
echo "Creating the user's directories..."
mkdir -p "$HOME" && echo "Created $HOME"
mkdir -p "$HOME/.config" && echo "Created $HOME/.config"
mkdir -p "$HOME/.local/share" && echo "Created $HOME/.local/share"
mkdir -p "$HOME/.local/bin" && echo "Created $HOME/.local/bin"
mkdir -p "$HOME/.cache" && echo "Created $HOME/.cache"

echo "Setting permissions for user '$USER'"
chown -R "$USER:$USER" "$HOME"

# Prevent sudo popups
touch "$HOME/.sudo_as_admin_successful"
