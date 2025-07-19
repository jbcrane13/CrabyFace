# Task Master AI Installers

This repository contains standalone installers for Task Master AI, a task management system for AI-driven development.

## Available Installers

### 1. Basic Node.js Installer (`install-taskmaster.js`)

A simple, straightforward installer that handles the most common installation scenarios.

**Features:**
- Automatic system requirement checks
- Global npm installation
- Project initialization
- Shell alias setup
- Git repository configuration

**Usage:**
```bash
node install-taskmaster.js [options]

# Quick installation with defaults
node install-taskmaster.js --yes

# Dry run to preview
node install-taskmaster.js --dry-run
```

### 2. Advanced Node.js Installer (`install-taskmaster-advanced.js`)

A comprehensive installer with multiple installation methods and enhanced features.

**Features:**
- Multiple installation methods (npm global/local, GitHub release/source)
- Progress bars for downloads
- Detailed system checks
- Interactive installation method selection
- Better error handling and recovery
- Local wrapper script generation
- Installation state tracking

**Usage:**
```bash
node install-taskmaster-advanced.js [options]

# Select installation method interactively
node install-taskmaster-advanced.js

# Install locally in project
node install-taskmaster-advanced.js --method npm-local

# Install from GitHub source
node install-taskmaster-advanced.js --method github-source
```

### 3. Bash Installer (`install-taskmaster.sh`)

A lightweight bash script for Unix-like systems (Linux, macOS).

**Features:**
- Minimal dependencies
- Fast execution
- System compatibility checks
- Local or global installation
- POSIX-compliant

**Usage:**
```bash
# Make executable first
chmod +x install-taskmaster.sh

# Run installer
./install-taskmaster.sh [options]

# Quick installation
./install-taskmaster.sh --yes

# Local installation
./install-taskmaster.sh --local
```

## Installation Options

All installers support these common options:

| Option | Description |
|--------|-------------|
| `-y, --yes` | Skip prompts and use default values |
| `--dry-run` | Preview changes without making them |
| `--skip-install` | Skip package installation |
| `--skip-init` | Skip project initialization |
| `--no-aliases` | Don't create shell aliases |
| `--no-git` | Skip git repository setup |
| `--no-git-tasks` | Don't track tasks in git |
| `--rules <profiles...>` | Specify rule profiles to install |
| `-h, --help` | Show help information |

## Quick Start

### One-line Installation

**Using curl (recommended):**
```bash
curl -fsSL https://raw.githubusercontent.com/eyaltoledano/claude-task-master/main/install-taskmaster.sh | bash
```

**Using wget:**
```bash
wget -qO- https://raw.githubusercontent.com/eyaltoledano/claude-task-master/main/install-taskmaster.sh | bash
```

**Using Node.js:**
```bash
npx https://raw.githubusercontent.com/eyaltoledano/claude-task-master/main/install-taskmaster.js
```

### Manual Installation

1. Download the installer of your choice
2. Run it with your preferred options
3. Follow the prompts (if not using `--yes`)

## System Requirements

- **Node.js**: Version 18.0.0 or higher
- **npm**: Comes with Node.js
- **Git**: Optional but recommended
- **Operating System**: Windows, macOS, or Linux

## Installation Methods Comparison

| Method | Pros | Cons |
|--------|------|------|
| NPM Global | Easy to use anywhere, Standard installation | Requires npm permissions |
| NPM Local | Project-specific version, No global pollution | Must use wrapper script |
| GitHub Release | Stable versions only, Predictable | May be behind latest |
| GitHub Source | Latest features, Development version | May be unstable |

## Troubleshooting

### Permission Errors

If you get permission errors during global installation:

**macOS/Linux:**
```bash
# Option 1: Use a Node version manager (recommended)
# Install nvm, then:
nvm use 18

# Option 2: Change npm prefix
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

**Windows:**
Run your terminal as Administrator or use a Node version manager like nvm-windows.

### Installation Verification

After installation, verify it worked:

```bash
# Global installation
task-master --version

# Local installation
./task-master-local --version
# or
./node_modules/.bin/task-master --version
```

### Firewall/Proxy Issues

If behind a corporate firewall:

```bash
# Set npm proxy
npm config set proxy http://proxy.company.com:8080
npm config set https-proxy http://proxy.company.com:8080

# Or use environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
```

## Post-Installation

After successful installation:

1. **Configure AI Models**
   ```bash
   task-master models --setup
   ```

2. **Add API Keys**
   Create `.env` file with your API keys:
   ```
   ANTHROPIC_API_KEY=your_key_here
   OPENAI_API_KEY=your_key_here
   ```

3. **Create Your First Project**
   ```bash
   # Create a PRD
   task-master parse-prd .taskmaster/docs/prd.txt
   
   # View tasks
   task-master list
   
   # Start working
   task-master next
   ```

## Uninstallation

To remove Task Master AI:

**Global installation:**
```bash
npm uninstall -g task-master-ai
```

**Local installation:**
```bash
npm uninstall task-master-ai
rm -f task-master-local  # Remove wrapper script
```

**Project files:**
```bash
rm -rf .taskmaster/  # Remove project data (careful!)
```

## Support

- **Documentation**: [GitHub Wiki](https://github.com/eyaltoledano/claude-task-master/wiki)
- **Issues**: [GitHub Issues](https://github.com/eyaltoledano/claude-task-master/issues)
- **Discussions**: [GitHub Discussions](https://github.com/eyaltoledano/claude-task-master/discussions)

## License

These installers are provided under the same license as Task Master AI (MIT with Commons Clause).