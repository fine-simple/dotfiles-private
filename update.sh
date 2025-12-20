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

# Check if decrypted folder exists
if [ ! -d "decrypted" ]; then
    echo "Error: decrypted folder not found. Run setup.sh first."
    exit 1
fi

# Check if hash file exists and compare
if [ -f ".decrypted.hash" ]; then
    echo "Checking if decrypted folder has changes..."
    current_hash=$(compute_hash)
    stored_hash=$(cat .decrypted.hash)
    
    if [ "$current_hash" = "$stored_hash" ]; then
        echo "No changes detected in decrypted folder. Nothing to update."
        exit 0
    else
        echo "Changes detected. Updating encrypted file..."
    fi
else
    echo "Hash file not found. Proceeding with encryption..."
fi

# Check if age is installed
if ! command -v age &> /dev/null; then
    echo "Error: age is not installed. Please install it first."
    exit 1
fi

# Check if key file exists
if [ ! -f "key" ]; then
    echo "Error: key file not found. Run setup.sh first to retrieve the key."
    exit 1
fi

# Create tar archive and encrypt it
echo "Creating encrypted archive..."
tar -cf - decrypted | age -e -i key > private-dotfiles.tar.age.new

# Replace old encrypted file with new one
echo "Replacing old encrypted file..."
mv private-dotfiles.tar.age.new private-dotfiles.tar.age

# Update hash file
echo "Updating hash file..."
compute_hash > .decrypted.hash

echo "Update complete! Encrypted file has been updated."
