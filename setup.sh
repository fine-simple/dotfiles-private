#!/bin/bash

set -e  # Exit on error

# Function to compute hash of decrypted folder
compute_hash() {
    if [ -d "decrypted" ]; then
        tar -cf - decrypted | sha256sum | awk '{print $1}'
    else
        echo ""
    fi
}

# Check if decrypted folder exists and hash matches
if [ -d "decrypted" ] && [ -f ".decrypted.hash" ]; then
    echo "Checking if decrypted folder is up to date..."
    current_hash=$(compute_hash)
    stored_hash=$(cat .decrypted.hash)
    
    if [ "$current_hash" = "$stored_hash" ]; then
        echo "Decrypted folder is already up to date. Skipping setup."
        exit 0
    else
        echo "Decrypted folder hash mismatch. Re-running setup..."
				rm -rf decrypted
    fi
fi

# Check if bw is installed, install if not
if ! command -v bw &> /dev/null; then
    echo "Bitwarden CLI not found. Installing..."
    if command -v snap &> /dev/null; then
        sudo snap install bw
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install bitwarden-cli
    else
        echo "Please install Bitwarden CLI manually from https://bitwarden.com/help/cli/"
        exit 1
    fi
fi

# Check if age is installed
if ! command -v age &> /dev/null; then
    echo "Error: age is not installed. Please install it first."
    exit 1
fi

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo "Error: stow is not installed. Please install it first."
    exit 1
fi

# Check if encrypted file exists
if [ ! -f "private-dotfiles.tar.age" ]; then
    echo "Error: private-dotfiles.tar.age not found"
    exit 1
fi

# Login to Bitwarden
echo "Logging into Bitwarden..."
bw login || echo "Already logged in or login failed. Continuing..."

# Unlock Bitwarden and store session key
export BW_SESSION=$(bw unlock --raw)

if [ -z "$BW_SESSION" ]; then
    echo "Error: Failed to unlock Bitwarden"
    exit 1
fi

# Get the notes from 'dotfiles-age' entry and save to key file
echo "Retrieving age key from Bitwarden..."
bw get notes dotfiles-age > key

if [ ! -s key ]; then
    echo "Error: Failed to retrieve key from Bitwarden"
    exit 1
fi

# Decrypt the private-dotfiles.tar.age using the key
echo "Decrypting private-dotfiles.tar.age..."
age -d -i key private-dotfiles.tar.age | tar -x

# Check if decrypted folder exists
if [ ! -d "decrypted" ]; then
    echo "Error: decrypted folder not found after extraction"
    exit 1
fi

# Stow dotfiles from decrypted folder to home directory
echo "Stowing dotfiles to home directory..."
cd decrypted
stow -t "$HOME" */
cd ..

# Store hash of decrypted folder for future checks
echo "Storing hash of decrypted folder..."
compute_hash > .decrypted.hash

echo "Setup complete!"
