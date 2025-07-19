#!/bin/bash
# Task Master AI Quick Installer
# Usage: curl -fsSL https://example.com/install.sh | bash

set -e

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Task Master AI Quick Installer${NC}"
echo "=============================="
echo

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    echo "Please install Node.js 18.0.0 or higher from https://nodejs.org"
    exit 1
fi

# Check Node version
NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}Error: Node.js 18.0.0 or higher is required${NC}"
    echo "Current version: $(node -v)"
    exit 1
fi

# Install Task Master AI globally
echo -e "${BLUE}Installing Task Master AI...${NC}"
npm install -g task-master-ai

# Initialize project if in a directory
if [ -w . ]; then
    echo
    echo -e "${BLUE}Initializing Task Master project...${NC}"
    task-master init --yes
fi

echo
echo -e "${GREEN}✅ Installation complete!${NC}"
echo
echo "Next steps:"
echo "  1. Configure AI models: task-master models --setup"
echo "  2. Add API keys to .env file"
echo "  3. Create a PRD and parse it: task-master parse-prd"
echo
echo "For more information: task-master --help"