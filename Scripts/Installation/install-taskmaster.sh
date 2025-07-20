#!/bin/bash

# Task Master AI Installer Script
# Simple bash installer for Task Master AI

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'
DIM='\033[2m'

# Configuration
PACKAGE_NAME="task-master-ai"
MIN_NODE_VERSION="18.0.0"
GITHUB_REPO="eyaltoledano/claude-task-master"

# Functions
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════╗"
    echo "║                                        ║"
    echo "║        Task Master AI Installer        ║"
    echo "║                                        ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${DIM}Quick installation script${NC}"
    echo
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        return 1
    fi
    return 0
}

version_compare() {
    # Compare two version strings
    # Returns 0 if $1 >= $2
    local version1=$1
    local version2=$2
    
    if [[ "$(printf '%s\n' "$version2" "$version1" | sort -V | head -n1)" == "$version2" ]]; then
        return 0
    else
        return 1
    fi
}

check_node_version() {
    local node_version=$(node --version | sed 's/v//')
    
    if version_compare "$node_version" "$MIN_NODE_VERSION"; then
        log_success "Node.js $node_version detected"
        return 0
    else
        log_error "Node.js $MIN_NODE_VERSION or higher required. Found: $node_version"
        return 1
    fi
}

check_requirements() {
    log_info "Checking system requirements..."
    
    local all_good=true
    
    # Check Node.js
    if check_command node; then
        if ! check_node_version; then
            all_good=false
        fi
    else
        log_error "Node.js is not installed"
        all_good=false
    fi
    
    # Check npm
    if check_command npm; then
        local npm_version=$(npm --version)
        log_success "npm $npm_version detected"
    else
        log_error "npm is not installed"
        all_good=false
    fi
    
    # Check git (optional)
    if check_command git; then
        local git_version=$(git --version | awk '{print $3}')
        log_success "Git $git_version detected"
    else
        log_warn "Git is not installed (optional)"
    fi
    
    if [ "$all_good" = false ]; then
        echo
        log_error "Please install missing requirements and try again"
        exit 1
    fi
}

install_global() {
    log_info "Installing Task Master AI globally..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "Would run: npm install -g $PACKAGE_NAME"
    else
        npm install -g "$PACKAGE_NAME"
    fi
    
    log_success "Task Master AI installed successfully"
}

install_local() {
    log_info "Installing Task Master AI locally..."
    
    if [ "$DRY_RUN" = true ]; then
        echo "Would run: npm install $PACKAGE_NAME"
    else
        npm install "$PACKAGE_NAME"
        
        # Create wrapper script
        cat > task-master-local << 'EOF'
#!/bin/bash
# Local Task Master wrapper
node_modules/.bin/task-master "$@"
EOF
        chmod +x task-master-local
        log_info "Created local wrapper script: ./task-master-local"
    fi
    
    log_success "Task Master AI installed locally"
}

initialize_project() {
    log_info "Initializing Task Master project..."
    
    local init_args=""
    
    [ "$SKIP_PROMPTS" = true ] && init_args="$init_args --yes"
    [ "$NO_ALIASES" = true ] && init_args="$init_args --no-aliases"
    [ "$NO_GIT" = true ] && init_args="$init_args --no-git"
    [ "$NO_GIT_TASKS" = true ] && init_args="$init_args --no-git-tasks"
    [ "$DRY_RUN" = true ] && init_args="$init_args --dry-run"
    
    if [ ! -z "$RULES" ]; then
        init_args="$init_args --rules $RULES"
    fi
    
    local cmd=""
    if [ "$INSTALL_METHOD" = "local" ]; then
        cmd="./node_modules/.bin/task-master"
    else
        cmd="task-master"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo "Would run: $cmd init $init_args"
    else
        $cmd init $init_args
    fi
    
    log_success "Project initialized successfully"
}

show_next_steps() {
    echo
    echo -e "${GREEN}${BOLD}✨ Installation Complete!${NC}"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo
    echo "1. Configure AI models and API keys"
    echo "   ${DIM}└─ Run: task-master models --setup${NC}"
    echo
    echo "2. Create a Product Requirements Document"
    echo "   ${DIM}└─ Use template: .taskmaster/templates/example_prd.txt${NC}"
    echo
    echo "3. Parse your PRD to generate tasks"
    echo "   ${DIM}└─ Run: task-master parse-prd .taskmaster/docs/prd.txt${NC}"
    echo
    echo "4. Start working on tasks"
    echo "   ${DIM}├─ View tasks: task-master list${NC}"
    echo "   ${DIM}└─ Get next task: task-master next${NC}"
    echo
    echo -e "${DIM}For more information, see the README.md file${NC}"
}

show_help() {
    cat << EOF
Task Master AI Installer

Usage: $0 [OPTIONS]

Options:
    -h, --help          Show this help message
    -y, --yes           Skip all prompts and use defaults
    -l, --local         Install locally instead of globally
    --dry-run           Show what would be done without making changes
    --skip-install      Skip npm install (assume already installed)
    --skip-init         Skip project initialization
    --no-aliases        Skip shell alias setup
    --no-git            Skip git repository initialization
    --no-git-tasks      Don't store tasks in git
    --rules PROFILES    Specify rule profiles (space-separated)

Examples:
    # Interactive global installation
    $0

    # Quick installation with defaults
    $0 --yes

    # Local installation
    $0 --local

    # Install with specific rules
    $0 --rules "claude cursor"

    # Dry run
    $0 --dry-run
EOF
}

# Parse arguments
SKIP_PROMPTS=false
INSTALL_METHOD="global"
DRY_RUN=false
SKIP_INSTALL=false
SKIP_INIT=false
NO_ALIASES=false
NO_GIT=false
NO_GIT_TASKS=false
RULES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -y|--yes)
            SKIP_PROMPTS=true
            shift
            ;;
        -l|--local)
            INSTALL_METHOD="local"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        --skip-init)
            SKIP_INIT=true
            shift
            ;;
        --no-aliases)
            NO_ALIASES=true
            shift
            ;;
        --no-git)
            NO_GIT=true
            shift
            ;;
        --no-git-tasks)
            NO_GIT_TASKS=true
            shift
            ;;
        --rules)
            shift
            RULES="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main installation flow
print_banner

# Check requirements
check_requirements

# Confirm installation
if [ "$SKIP_PROMPTS" = false ]; then
    echo
    echo -e "${YELLOW}This will install Task Master AI ${INSTALL_METHOD}ly.${NC}"
    read -p "Continue? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Install package
if [ "$SKIP_INSTALL" = false ]; then
    if [ "$INSTALL_METHOD" = "local" ]; then
        install_local
    else
        install_global
    fi
else
    log_info "Skipping package installation (--skip-install)"
fi

# Initialize project
if [ "$SKIP_INIT" = false ]; then
    initialize_project
else
    log_info "Skipping project initialization (--skip-init)"
fi

# Show completion message
if [ "$DRY_RUN" = false ]; then
    show_next_steps
else
    echo
    log_info "Dry run complete. No changes were made."
fi

exit 0