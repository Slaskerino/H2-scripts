#!/bin/bash

# Stop on error
set -e

# Name of environment
VENV_NAME=".venv"

# Check if python3-venv is installed
if ! dpkg -s python3-venv &> /dev/null; then
    echo "python3-venv not found. Installing..."
    sudo apt update && sudo apt install -y python3-venv
fi

# Create virtual environment if not exists
if [ ! -d "$VENV_NAME" ]; then
    python3 -m venv "$VENV_NAME"
    echo "Virtual environment created in $VENV_NAME"
fi

# Activate virtual environment
source "$VENV_NAME/bin/activate"

# Upgrade pip and install Ansible
pip install --upgrade pip
pip install -r requirements.txt


# Print Ansible version to confirm install
ansible --version

echo "✅ Setup complete. Virtual environment is ready."
