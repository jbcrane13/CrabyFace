#!/usr/bin/env node

/**
 * Task Master AI Installer
 * A standalone installer that downloads and sets up Task Master AI
 */

import { execSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import https from 'https';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import readline from 'readline';
import os from 'os';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ANSI color codes for console output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  dim: '\x1b[2m',
  bold: '\x1b[1m'
};

// Logging utilities
const log = {
  info: (msg) => console.log(`${colors.blue}ℹ️  ${msg}${colors.reset}`),
  success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  warn: (msg) => console.log(`${colors.yellow}⚠️  ${msg}${colors.reset}`),
  error: (msg) => console.error(`${colors.red}❌ ${msg}${colors.reset}`),
  dim: (msg) => console.log(`${colors.dim}${msg}${colors.reset}`)
};

// Configuration
const CONFIG = {
  packageName: 'task-master-ai',
  npmRegistry: 'https://registry.npmjs.org',
  requiredNodeVersion: '18.0.0',
  directories: {
    taskmaster: '.taskmaster',
    tasks: '.taskmaster/tasks',
    docs: '.taskmaster/docs',
    reports: '.taskmaster/reports',
    templates: '.taskmaster/templates'
  }
};

// Helper to prompt user
function prompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer);
    });
  });
}

// Check Node.js version
function checkNodeVersion() {
  const currentVersion = process.version.slice(1); // Remove 'v' prefix
  const required = CONFIG.requiredNodeVersion;
  
  const current = currentVersion.split('.').map(Number);
  const min = required.split('.').map(Number);
  
  for (let i = 0; i < min.length; i++) {
    if (current[i] > min[i]) return true;
    if (current[i] < min[i]) {
      log.error(`Node.js ${required} or higher is required. You have ${currentVersion}`);
      process.exit(1);
    }
  }
  return true;
}

// Check if npm is available
function checkNpm() {
  try {
    execSync('npm --version', { stdio: 'pipe' });
    return true;
  } catch (error) {
    log.error('npm is not installed. Please install Node.js and npm first.');
    process.exit(1);
  }
}

// Check if git is available
function checkGit() {
  try {
    execSync('git --version', { stdio: 'pipe' });
    return true;
  } catch (error) {
    return false;
  }
}

// Install Task Master AI globally
async function installPackage(options = {}) {
  log.info('Installing Task Master AI...');
  
  try {
    const installCmd = options.dryRun 
      ? `npm install -g ${CONFIG.packageName} --dry-run`
      : `npm install -g ${CONFIG.packageName}`;
    
    if (options.silent) {
      execSync(installCmd, { stdio: 'pipe' });
    } else {
      execSync(installCmd, { stdio: 'inherit' });
    }
    
    log.success('Task Master AI installed successfully');
    return true;
  } catch (error) {
    log.error('Failed to install Task Master AI');
    log.dim(error.message);
    return false;
  }
}

// Initialize project structure
async function initializeProject(options = {}) {
  const targetDir = process.cwd();
  log.info(`Initializing project in ${targetDir}`);
  
  // Create directory structure
  for (const [key, dir] of Object.entries(CONFIG.directories)) {
    const dirPath = path.join(targetDir, dir);
    if (!fs.existsSync(dirPath)) {
      if (!options.dryRun) {
        fs.mkdirSync(dirPath, { recursive: true });
      }
      log.info(`Created directory: ${dir}`);
    }
  }
  
  // Run task-master init with options
  const initArgs = ['init'];
  
  if (options.yes) initArgs.push('--yes');
  if (options.rules && options.rules.length > 0) {
    initArgs.push('--rules', ...options.rules);
  }
  if (options.skipAliases) initArgs.push('--no-aliases');
  if (options.skipGit) initArgs.push('--no-git');
  if (options.skipGitTasks) initArgs.push('--no-git-tasks');
  if (options.dryRun) initArgs.push('--dry-run');
  
  try {
    if (!options.dryRun) {
      execSync(`task-master ${initArgs.join(' ')}`, { 
        stdio: options.silent ? 'pipe' : 'inherit',
        cwd: targetDir 
      });
    } else {
      log.info(`Would run: task-master ${initArgs.join(' ')}`);
    }
    
    log.success('Project initialized successfully');
    return true;
  } catch (error) {
    log.error('Failed to initialize project');
    log.dim(error.message);
    return false;
  }
}

// Display banner
function displayBanner() {
  console.clear();
  console.log(`
${colors.cyan}╔════════════════════════════════════════╗
║                                        ║
║        Task Master AI Installer        ║
║                                        ║
╚════════════════════════════════════════╝${colors.reset}

${colors.dim}Automated installation and setup tool${colors.reset}
`);
}

// Display next steps
function displayNextSteps() {
  console.log(`
${colors.cyan}${colors.bold}✨ Installation Complete!${colors.reset}

${colors.yellow}Next steps:${colors.reset}

1. ${colors.blue}Configure AI models and API keys${colors.reset}
   ${colors.dim}├─ Run: ${colors.cyan}task-master models --setup${colors.reset}
   ${colors.dim}└─ Add API keys to .env file${colors.reset}

2. ${colors.blue}Create a Product Requirements Document${colors.reset}
   ${colors.dim}└─ Use the example at: .taskmaster/templates/example_prd.txt${colors.reset}

3. ${colors.blue}Parse your PRD to generate tasks${colors.reset}
   ${colors.dim}└─ Run: ${colors.cyan}task-master parse-prd .taskmaster/docs/prd.txt${colors.reset}

4. ${colors.blue}Start working on tasks${colors.reset}
   ${colors.dim}├─ View tasks: ${colors.cyan}task-master list${colors.reset}
   ${colors.dim}└─ Get next task: ${colors.cyan}task-master next${colors.reset}

${colors.dim}For more information, see the README.md file${colors.reset}
`);
}

// Main installation flow
async function main() {
  // Parse command line arguments
  const args = process.argv.slice(2);
  const options = {
    yes: args.includes('--yes') || args.includes('-y'),
    dryRun: args.includes('--dry-run'),
    silent: args.includes('--silent'),
    skipInstall: args.includes('--skip-install'),
    skipInit: args.includes('--skip-init'),
    skipAliases: args.includes('--no-aliases'),
    skipGit: args.includes('--no-git'),
    skipGitTasks: args.includes('--no-git-tasks'),
    rules: []
  };
  
  // Parse rules if provided
  const rulesIndex = args.findIndex(arg => arg === '--rules' || arg === '-r');
  if (rulesIndex !== -1) {
    let i = rulesIndex + 1;
    while (i < args.length && !args[i].startsWith('--')) {
      options.rules.push(args[i]);
      i++;
    }
  }
  
  // Show help if requested
  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Task Master AI Installer

Usage: node install-taskmaster.js [options]

Options:
  -y, --yes              Skip all prompts and use defaults
  --dry-run              Show what would be done without making changes
  --silent               Suppress output (for automated installations)
  --skip-install         Skip npm install (assume already installed)
  --skip-init            Skip project initialization
  --no-aliases           Skip shell alias setup
  --no-git               Skip git repository initialization
  --no-git-tasks         Don't store tasks in git
  --rules <profiles...>  Specify rule profiles to install
  -h, --help             Show this help message

Examples:
  # Interactive installation
  node install-taskmaster.js

  # Automated installation with defaults
  node install-taskmaster.js --yes

  # Install with specific rules
  node install-taskmaster.js --rules claude cursor

  # Dry run to see what would happen
  node install-taskmaster.js --dry-run
`);
    process.exit(0);
  }
  
  // Display banner
  if (!options.silent) {
    displayBanner();
  }
  
  // Perform checks
  log.info('Checking system requirements...');
  checkNodeVersion();
  checkNpm();
  const hasGit = checkGit();
  
  if (!hasGit && !options.skipGit) {
    log.warn('Git is not installed. Git features will be skipped.');
    options.skipGit = true;
  }
  
  // Install package
  if (!options.skipInstall) {
    const installed = await installPackage(options);
    if (!installed && !options.dryRun) {
      process.exit(1);
    }
  } else {
    log.info('Skipping package installation (--skip-install flag)');
  }
  
  // Initialize project
  if (!options.skipInit) {
    const initialized = await initializeProject(options);
    if (!initialized && !options.dryRun) {
      process.exit(1);
    }
  } else {
    log.info('Skipping project initialization (--skip-init flag)');
  }
  
  // Display next steps
  if (!options.silent && !options.dryRun) {
    displayNextSteps();
  }
  
  if (options.dryRun) {
    log.info('Dry run complete. No changes were made.');
  }
}

// Run the installer
main().catch(error => {
  log.error('Installation failed');
  console.error(error);
  process.exit(1);
});