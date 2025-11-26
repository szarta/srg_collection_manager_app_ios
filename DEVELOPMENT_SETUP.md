# Development Environment Setup

## Architecture Overview

**Primary Development**: Linux laptop/PC via SSH
**Build Server**: M4 Mac Mini with monitor/keyboard/mouse attached

```
┌─────────────────────────┐
│   Linux Dev Machine     │
│  (Laptop or Desktop)    │
│                         │
│  • Code editing         │
│  • Git operations       │
│  • SSH to Mac           │
│  • VS Code Remote SSH   │
└────────────┬────────────┘
             │ SSH
             ↓
┌─────────────────────────┐
│     Mac Mini (M4)       │
│  Monitor/KB/Mouse       │
│                         │
│  • Xcode IDE            │
│  • iOS Simulator        │
│  • Build tools          │
│  • Visual debugging     │
│  • Direct use when      │
│    GUI needed           │
└─────────────────────────┘
```

---

## Mac Mini Initial Setup

### 1. macOS Configuration (On Mac directly)

```bash
# Complete initial macOS setup wizard
# Sign in with Apple ID
# Set computer name

# Enable Remote Login (SSH)
sudo systemsetup -setremotelogin on

# Enable developer mode
sudo DevToolsSecurity -enable

# Get IP address (note this for SSH from Linux)
ifconfig | grep "inet "
# Or use: System Settings → Network → Wi-Fi → Details → TCP/IP
```

### 2. Install Xcode (Via Mac App Store)

```bash
# Open App Store
# Search for "Xcode"
# Install (15-20 GB, takes 30-60 minutes)

# After installation, install command line tools:
xcode-select --install

# Accept license
sudo xcodebuild -license accept

# Verify installation
xcodebuild -version
# Should show: Xcode 16.x
```

### 3. Install Homebrew (Package Manager)

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add to PATH (M4 Mac uses Apple Silicon path)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Verify
brew --version
```

### 4. Install Development Tools

```bash
# Node.js and npm (for Claude Code)
brew install node

# Verify
node --version
npm --version

# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Verify
claude --version

# Optional but useful tools
brew install git    # Latest Git
brew install gh     # GitHub CLI
brew install tree   # Directory tree viewer
```

### 5. SSH Key Setup (Optional but Recommended)

```bash
# On Mac, generate SSH key for GitHub
ssh-keygen -t ed25519 -C "your_email@example.com"

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# Copy public key to GitHub
cat ~/.ssh/id_ed25519.pub
# Add at: https://github.com/settings/keys
```

---

## Linux Dev Machine Setup

### 1. SSH Configuration

```bash
# Test connection
ssh brandon@mac-mini-ip

# Set up passwordless login (optional but convenient)
ssh-keygen -t ed25519 -C "your_email@example.com"
ssh-copy-id brandon@mac-mini-ip

# Create SSH config for easy access
nano ~/.ssh/config

# Add:
Host mac-mini
    HostName 192.168.1.XXX  # Your Mac's IP
    User brandon
    IdentityFile ~/.ssh/id_ed25519

# Now you can just: ssh mac-mini
```

### 2. VS Code Remote SSH (Recommended)

```bash
# Install VS Code if not already installed
# Download from: https://code.visualstudio.com/

# Install Remote SSH extension
code --install-extension ms-vscode-remote.remote-ssh

# Connect to Mac Mini:
# 1. Open VS Code
# 2. Press F1 or Ctrl+Shift+P
# 3. Type "Remote-SSH: Connect to Host"
# 4. Enter: mac-mini (or IP address)
# 5. VS Code will connect and install server components on Mac
```

### 3. Install Extensions on Remote (Mac)

When connected via VS Code Remote SSH, install these extensions **on the Mac**:

```
• Swift (for syntax highlighting and language support)
• GitLens (enhanced Git integration)
• EditorConfig (code formatting)
```

---

## Daily Development Workflow

### Option A: Command Line via SSH

```bash
# From Linux
ssh mac-mini

# Navigate to project
cd ~/dev/get-diced-ios

# Edit files
vim GetDiced/Models/Card.swift
# or nano, emacs, etc.

# Build project
xcodebuild -scheme GetDiced -sdk iphonesimulator

# Run tests
xcodebuild test -scheme GetDiced -destination 'platform=iOS Simulator,name=iPhone 15'

# Git operations
git status
git add .
git commit -m "Update Card model"
git push
```

### Option B: VS Code Remote SSH (Recommended)

```bash
# From Linux, open VS Code
code

# Connect to Mac Mini via Remote SSH
# F1 → "Remote-SSH: Connect to Host" → mac-mini

# Open project folder on Mac
# File → Open Folder → ~/dev/get-diced-ios

# Now you have:
# • Full IDE experience
# • Swift syntax highlighting
# • Autocomplete
# • Git integration
# • Integrated terminal
# • Claude Code works in remote context!
```

### When You Need GUI (Simulator, Visual Debugging)

**Just walk over to the Mac Mini and use it directly!**

- Open Xcode on Mac
- Run simulator (Cmd+R)
- Visual debugging
- UI testing
- Asset management

---

## Common Build Commands

### Building

```bash
# Build for simulator (via SSH)
xcodebuild -scheme GetDiced -sdk iphonesimulator -configuration Debug

# Build for physical device
xcodebuild -scheme GetDiced -sdk iphoneos -configuration Debug

# Clean build
xcodebuild clean -scheme GetDiced

# Build specific destination
xcodebuild -scheme GetDiced -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Testing

```bash
# Run all tests
xcodebuild test -scheme GetDiced -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -scheme GetDiced -only-testing:GetDicedTests/CardModelTests

# Generate code coverage
xcodebuild test -scheme GetDiced -enableCodeCoverage YES
```

### Archiving (For TestFlight/App Store)

```bash
# Create archive
xcodebuild archive \
  -scheme GetDiced \
  -archivePath ./build/GetDiced.xcarchive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath ./build/GetDiced.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist
```

---

## Git Workflow

### Recommended Setup

```bash
# Clone repository on Mac Mini
ssh mac-mini
cd ~/dev
git clone https://github.com/yourusername/get-diced-ios.git
cd get-diced-ios

# Set up Git identity
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

### Working with Git via SSH

```bash
# From Linux, SSH to Mac
ssh mac-mini
cd ~/dev/get-diced-ios

# Normal Git workflow
git checkout -b feature/new-screen
# Make changes
git add .
git commit -m "Add new screen"
git push origin feature/new-screen
```

### Or via VS Code Remote SSH

- Full Git UI in VS Code
- Visual diffs
- Commit/push/pull via GUI
- GitLens for advanced features

---

## File Transfer Between Linux and Mac

### Option 1: Git (Recommended)

```bash
# Work on Linux, commit and push
git push

# On Mac, pull changes
ssh mac-mini
cd ~/dev/get-diced-ios
git pull
```

### Option 2: SCP (For Non-Git Files)

```bash
# From Linux to Mac
scp file.txt mac-mini:~/dev/get-diced-ios/

# From Mac to Linux
scp mac-mini:~/dev/get-diced-ios/file.txt ./

# Recursive directory
scp -r directory/ mac-mini:~/dev/
```

### Option 3: VS Code Remote SSH

- Just edit files directly on Mac via VS Code
- Files are on Mac, edited from Linux
- No transfer needed!

---

## Troubleshooting

### Can't Connect via SSH

```bash
# On Mac, verify SSH is enabled
sudo systemsetup -getremotelogin
# Should show: Remote Login: On

# Check firewall (System Settings → Network → Firewall)
# Allow incoming connections for SSH

# Verify IP address
ifconfig | grep "inet "
```

### Command Not Found After Installing via Homebrew

```bash
# Add Homebrew to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
```

### Xcode Command Line Tools Issues

```bash
# Reset command line tools
sudo xcode-select --reset

# Reinstall
xcode-select --install

# Point to Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### VS Code Can't Connect

```bash
# Kill VS Code server on Mac and retry
ssh mac-mini "pkill -f vscode-server"

# Reconnect from VS Code
```

---

## Performance Tips

### Keep Mac Mini Always On

```bash
# System Settings → Energy Saver
# • Prevent automatic sleeping on power adapter: ON
# • Wake for network access: ON
```

### Use SSH Multiplexing (Faster Connections)

```bash
# Add to ~/.ssh/config on Linux
Host mac-mini
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600

# Create sockets directory
mkdir -p ~/.ssh/sockets
```

---

## Summary

### Your Workflow:
1. **90% of time**: Code via SSH or VS Code Remote from Linux
2. **10% of time**: Walk to Mac Mini for simulator/GUI work

### Advantages:
- ✅ Comfortable Linux environment for coding
- ✅ Full Xcode/simulator access when needed
- ✅ No VNC/remote desktop complexity
- ✅ Claude Code works via SSH
- ✅ Best of both worlds

### Key Tools:
- **SSH**: Command line access from Linux
- **VS Code Remote SSH**: Full IDE from Linux
- **Xcode**: Direct use on Mac for GUI needs
- **Claude Code**: Works in both SSH and VS Code Remote contexts

---

**Last Updated**: November 24, 2024
**Status**: Ready for Mac Mini arrival
