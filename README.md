# Private Dotfiles Manager

Secure management of private dotfiles using age encryption with Bitwarden key storage.

## Overview

This repository manages encrypted dotfiles that are stored in `private-dotfiles.tar.age` and deployed to your home directory using GNU stow. The encryption key is securely stored in Bitwarden, and hash-based caching ensures efficient operations.

## Prerequisites

- **age** - File encryption tool
- **stow** - Symlink farm manager
- **Bitwarden CLI (bw)** - Auto-installed if not present (requires snap or homebrew)
- **tar** - Archive utility
- **sha256sum** - Hash computation

## Setup

### Initial Setup

1. Ensure you have a Bitwarden account with an entry called `dotfiles-age` containing the age key in the notes field
2. Run the setup script:

```bash
./setup.sh
```

This will:

- Install Bitwarden CLI if needed
- Login and unlock Bitwarden
- Retrieve the age key from the `dotfiles-age` entry
- Decrypt `private-dotfiles.tar.age` to the `decrypted/` folder
- Stow all subdirectories from `decrypted/` to your home directory
- Store a hash of the decrypted folder for future checks

### Subsequent Runs

The setup script is intelligent - if the `decrypted/` folder exists and its hash matches the stored hash, the entire setup process is skipped. This prevents unnecessary Bitwarden authentication and decryption.

## Updating Encrypted Archive

After modifying files in the `decrypted/` directory:

```bash
./update.sh
```

This will:

- Check if changes were made (compares current hash with stored hash)
- Skip if no changes detected
- Create a new encrypted archive from the `decrypted/` folder
- Replace the old `private-dotfiles.tar.age` file
- Update the stored hash

## Directory Structure

```
private-dotfiles/
├── setup.sh                    # Decrypt and deploy dotfiles
├── update.sh                   # Encrypt and update archive
├── private-dotfiles.tar.age    # Encrypted dotfiles archive
├── key                         # Age encryption key (from Bitwarden)
├── .decrypted.hash             # Hash of decrypted folder (for caching)
└── decrypted/                  # Decrypted dotfiles
```

## Workflow

### First Time Setup

1. Create your dotfiles structure in `decrypted/` with stow-compatible subdirectories
2. Run `./update.sh` to create the encrypted archive
3. Commit `private-dotfiles.tar.age` to the repository
4. Store your age key in Bitwarden under the `dotfiles-age` entry

### On a New Machine

1. Clone this repository
2. Run `./setup.sh`
3. Enter your Bitwarden credentials when prompted
4. Your dotfiles will be symlinked to your home directory

### Making Changes

1. Modify files in `decrypted/` or your home directory (they're symlinked)
2. Run `./update.sh` to encrypt and update the archive
3. Commit the updated `private-dotfiles.tar.age`

## Security Notes

- The `key` file is not tracked in git (add to .gitignore)
- The encryption key is stored securely in Bitwarden
- Only the encrypted archive is committed to the repository
- Hash-based caching prevents unnecessary decryption operations

## Troubleshooting

**Setup skipped when it shouldn't be:**

- Delete `.decrypted.hash` and run `./setup.sh` again

**Update not detecting changes:**

- Verify files in `decrypted/` were actually modified
- Delete `.decrypted.hash` and run `./update.sh` again

**Bitwarden authentication issues:**

- Run `bw logout` then `./setup.sh` for a fresh login
- Verify the `dotfiles-age` entry exists in your Bitwarden vault

**Stow conflicts:**

- Manually resolve conflicting files in your home directory
- Use `stow -n` to preview what would be stowed without actually doing it
