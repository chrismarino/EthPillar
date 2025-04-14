#!/bin/bash

# Update package list and install prerequisites
sudo apt update
sudo apt install -y curl build-essential
# sudo apt install xsel # Needed for serve.
# sudo apt install xclip # Needed for serve. 

# Install NVM (Node Version Manager)
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

# Load NVM into the current shell session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify NVM installation
if ! command -v nvm &> /dev/null; then
    echo "NVM installation failed. Please check the installation process."
    exit 1
fi

# Install Node.js version 16
echo "Installing Node.js version 16..."
nvm install 16

# Use Node.js version 16
nvm use 16

# Set Node.js version 16 as the default
nvm alias default 16

# Verify Node.js and npm installation
echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

# Install Yarn globally
echo "Installing Yarn..."
npm install -g yarn

# Verify Yarn installation
if ! command -v yarn &> /dev/null; then
    echo "Yarn installation failed. Please check the installation process."
    exit 1
fi
# Install serve
yarn global add serve@14.2.4

echo "Yarn version: $(yarn -v)"
echo "Node.js, NVM, and Yarn installation complete. Node.js version 16 is now in use."