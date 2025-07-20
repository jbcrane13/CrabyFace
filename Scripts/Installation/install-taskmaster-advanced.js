#!/usr/bin/env node

/**
 * Task Master AI Advanced Installer
 * Comprehensive installer with multiple installation methods
 */

import { execSync, spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import https from 'https';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import readline from 'readline';
import os from 'os';
import { createWriteStream } from 'fs';
import { pipeline } from 'stream/promises';
import { promisify } from 'util';
import { tmpdir } from 'os';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ANSI color codes and styling
const styles = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  underline: '\x1b[4m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m'
};

// Enhanced logging with emojis and styling
const log = {
  info: (msg) => console.log(`${styles.blue}ℹ️  ${msg}${styles.reset}`),
  success: (msg) => console.log(`${styles.green}✅ ${msg}${styles.reset}`),
  warn: (msg) => console.log(`${styles.yellow}⚠️  ${msg}${styles.reset}`),
  error: (msg) => console.error(`${styles.red}❌ ${msg}${styles.reset}`),
  dim: (msg) => console.log(`${styles.dim}${msg}${styles.reset}`),
  step: (num, total, msg) => console.log(`${styles.cyan}[${num}/${total}]${styles.reset} ${msg}`),
  subStep: (msg) => console.log(`   ${styles.dim}└─${styles.reset} ${msg}`)
};

// Progress bar for downloads
class ProgressBar {
  constructor(total, label = 'Progress') {
    this.total = total;
    this.current = 0;
    this.label = label;
    this.width = 40;
  }

  update(current) {
    this.current = current;
    const percentage = Math.floor((current / this.total) * 100);
    const filled = Math.floor((current / this.total) * this.width);
    const empty = this.width - filled;
    
    process.stdout.write('\r' + styles.dim + this.label + ': ' + styles.reset);
    process.stdout.write('[');
    process.stdout.write(styles.green + '█'.repeat(filled) + styles.reset);
    process.stdout.write(' '.repeat(empty));
    process.stdout.write('] ');
    process.stdout.write(percentage + '%');
    
    if (current >= this.total) {
      process.stdout.write('\n');
    }
  }
}

// Configuration
const CONFIG = {
  packageName: 'task-master-ai',
  npmRegistry: 'https://registry.npmjs.org',
  requiredNodeVersion: '18.0.0',
  githubRepo: 'eyaltoledano/claude-task-master',
  directories: {
    taskmaster: '.taskmaster',
    tasks: '.taskmaster/tasks',
    docs: '.taskmaster/docs',
    reports: '.taskmaster/reports',
    templates: '.taskmaster/templates'
  },
  installMethods: {
    NPM_GLOBAL: 'npm-global',
    NPM_LOCAL: 'npm-local',
    GITHUB_RELEASE: 'github-release',
    GITHUB_SOURCE: 'github-source'
  }
};

// Installation state
class InstallationState {
  constructor() {
    this.steps = [];
    this.currentStep = 0;
    this.errors = [];
    this.warnings = [];
  }

  addStep(description) {
    this.steps.push({
      description,
      status: 'pending',
      startTime: null,
      endTime: null
    });
  }

  startStep(index) {
    this.currentStep = index;
    this.steps[index].status = 'running';
    this.steps[index].startTime = Date.now();
    log.step(index + 1, this.steps.length, this.steps[index].description);
  }

  completeStep(index, status = 'success') {
    this.steps[index].status = status;
    this.steps[index].endTime = Date.now();
  }

  addError(error) {
    this.errors.push(error);
  }

  addWarning(warning) {
    this.warnings.push(warning);
  }

  getSummary() {
    const successful = this.steps.filter(s => s.status === 'success').length;
    const failed = this.steps.filter(s => s.status === 'failed').length;
    const totalTime = this.steps.reduce((acc, step) => {
      if (step.endTime && step.startTime) {
        return acc + (step.endTime - step.startTime);
      }
      return acc;
    }, 0);

    return {
      successful,
      failed,
      totalTime: Math.round(totalTime / 1000),
      errors: this.errors,
      warnings: this.warnings
    };
  }
}

// System requirements checker
class SystemChecker {
  static checkNodeVersion() {
    const currentVersion = process.version.slice(1);
    const required = CONFIG.requiredNodeVersion;
    
    const current = currentVersion.split('.').map(Number);
    const min = required.split('.').map(Number);
    
    for (let i = 0; i < min.length; i++) {
      if (current[i] > min[i]) return { success: true, version: currentVersion };
      if (current[i] < min[i]) {
        return { 
          success: false, 
          version: currentVersion,
          message: `Node.js ${required} or higher is required. You have ${currentVersion}`
        };
      }
    }
    return { success: true, version: currentVersion };
  }

  static checkNpm() {
    try {
      const version = execSync('npm --version', { stdio: 'pipe' }).toString().trim();
      return { success: true, version };
    } catch (error) {
      return { 
        success: false, 
        message: 'npm is not installed. Please install Node.js and npm first.'
      };
    }
  }

  static checkGit() {
    try {
      const version = execSync('git --version', { stdio: 'pipe' }).toString().trim();
      return { success: true, version };
    } catch (error) {
      return { 
        success: false, 
        message: 'Git is not installed. Git features will be disabled.'
      };
    }
  }

  static async checkInternetConnection() {
    return new Promise((resolve) => {
      https.get('https://registry.npmjs.org', (res) => {
        resolve({ success: res.statusCode === 200 });
      }).on('error', () => {
        resolve({ 
          success: false, 
          message: 'No internet connection detected.'
        });
      });
    });
  }

  static checkWritePermissions(dir = process.cwd()) {
    try {
      const testFile = path.join(dir, '.taskmaster-test-' + Date.now());
      fs.writeFileSync(testFile, 'test');
      fs.unlinkSync(testFile);
      return { success: true };
    } catch (error) {
      return { 
        success: false, 
        message: `No write permissions in ${dir}`
      };
    }
  }

  static async runAllChecks() {
    const checks = {
      node: this.checkNodeVersion(),
      npm: this.checkNpm(),
      git: this.checkGit(),
      internet: await this.checkInternetConnection(),
      permissions: this.checkWritePermissions()
    };

    const allPassed = Object.values(checks).every(check => check.success);
    return { allPassed, checks };
  }
}

// Installation methods
class Installer {
  constructor(options, state) {
    this.options = options;
    this.state = state;
  }

  async installNpmGlobal() {
    try {
      const cmd = this.options.dryRun 
        ? `npm install -g ${CONFIG.packageName} --dry-run`
        : `npm install -g ${CONFIG.packageName}`;
      
      if (this.options.silent) {
        execSync(cmd, { stdio: 'pipe' });
      } else {
        execSync(cmd, { stdio: 'inherit' });
      }
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async installNpmLocal() {
    try {
      const cmd = this.options.dryRun 
        ? `npm install ${CONFIG.packageName} --dry-run`
        : `npm install ${CONFIG.packageName}`;
      
      if (this.options.silent) {
        execSync(cmd, { stdio: 'pipe' });
      } else {
        execSync(cmd, { stdio: 'inherit' });
      }
      
      // Create local wrapper script
      if (!this.options.dryRun) {
        const wrapperScript = `#!/usr/bin/env node
import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const taskMasterPath = join(__dirname, 'node_modules', '.bin', 'task-master');
const child = spawn(taskMasterPath, process.argv.slice(2), { stdio: 'inherit' });
child.on('exit', (code) => process.exit(code));
`;
        fs.writeFileSync('./task-master-local.js', wrapperScript);
        fs.chmodSync('./task-master-local.js', '755');
        log.subStep('Created local wrapper script: ./task-master-local.js');
      }
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async downloadFile(url, destination) {
    return new Promise((resolve, reject) => {
      const file = createWriteStream(destination);
      
      https.get(url, (response) => {
        if (response.statusCode === 302 || response.statusCode === 301) {
          // Follow redirect
          return this.downloadFile(response.headers.location, destination)
            .then(resolve)
            .catch(reject);
        }
        
        if (response.statusCode !== 200) {
          reject(new Error(`Failed to download: ${response.statusCode}`));
          return;
        }
        
        const totalSize = parseInt(response.headers['content-length'], 10);
        const progressBar = new ProgressBar(totalSize, 'Download');
        let downloaded = 0;
        
        response.on('data', (chunk) => {
          downloaded += chunk.length;
          progressBar.update(downloaded);
        });
        
        response.pipe(file);
        
        file.on('finish', () => {
          file.close();
          resolve({ success: true });
        });
      }).on('error', (err) => {
        fs.unlink(destination, () => {});
        reject(err);
      });
    });
  }

  async installFromGithubRelease() {
    try {
      // Get latest release info
      const releaseUrl = `https://api.github.com/repos/${CONFIG.githubRepo}/releases/latest`;
      
      const releaseData = await new Promise((resolve, reject) => {
        https.get(releaseUrl, { headers: { 'User-Agent': 'TaskMaster-Installer' } }, (res) => {
          let data = '';
          res.on('data', chunk => data += chunk);
          res.on('end', () => {
            try {
              resolve(JSON.parse(data));
            } catch (e) {
              reject(e);
            }
          });
        }).on('error', reject);
      });
      
      if (!releaseData.tarball_url) {
        throw new Error('No release found');
      }
      
      const tempDir = path.join(tmpdir(), 'taskmaster-install-' + Date.now());
      fs.mkdirSync(tempDir, { recursive: true });
      
      const tarballPath = path.join(tempDir, 'taskmaster.tar.gz');
      await this.downloadFile(releaseData.tarball_url, tarballPath);
      
      // Extract and install using tar command
      execSync(`tar -xzf ${tarballPath} -C ${tempDir}`, { stdio: 'pipe' });
      
      // Find extracted directory
      const extracted = fs.readdirSync(tempDir).find(f => f.startsWith('eyaltoledano-claude-task-master'));
      if (!extracted) {
        throw new Error('Failed to extract release');
      }
      
      const extractedPath = path.join(tempDir, extracted);
      
      // Install from extracted directory
      execSync('npm install -g .', { 
        cwd: extractedPath,
        stdio: this.options.silent ? 'pipe' : 'inherit'
      });
      
      // Cleanup
      fs.rmSync(tempDir, { recursive: true, force: true });
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async installFromGithubSource() {
    try {
      const cmd = `npm install -g git+https://github.com/${CONFIG.githubRepo}.git`;
      
      if (this.options.silent) {
        execSync(cmd, { stdio: 'pipe' });
      } else {
        execSync(cmd, { stdio: 'inherit' });
      }
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async install(method) {
    log.subStep(`Using ${method} installation method`);
    
    switch (method) {
      case CONFIG.installMethods.NPM_GLOBAL:
        return await this.installNpmGlobal();
      case CONFIG.installMethods.NPM_LOCAL:
        return await this.installNpmLocal();
      case CONFIG.installMethods.GITHUB_RELEASE:
        return await this.installFromGithubRelease();
      case CONFIG.installMethods.GITHUB_SOURCE:
        return await this.installFromGithubSource();
      default:
        return { success: false, error: 'Unknown installation method' };
    }
  }
}

// Project initializer
class ProjectInitializer {
  constructor(options, state) {
    this.options = options;
    this.state = state;
  }

  async initialize() {
    const targetDir = process.cwd();
    log.subStep(`Initializing in ${targetDir}`);
    
    // Create directory structure
    for (const [key, dir] of Object.entries(CONFIG.directories)) {
      const dirPath = path.join(targetDir, dir);
      if (!fs.existsSync(dirPath)) {
        if (!this.options.dryRun) {
          fs.mkdirSync(dirPath, { recursive: true });
        }
        log.subStep(`Created ${dir}`);
      }
    }
    
    // Build init command arguments
    const initArgs = ['init'];
    
    if (this.options.yes) initArgs.push('--yes');
    if (this.options.rules && this.options.rules.length > 0) {
      initArgs.push('--rules', ...this.options.rules);
    }
    if (this.options.skipAliases) initArgs.push('--no-aliases');
    if (this.options.skipGit) initArgs.push('--no-git');
    if (this.options.skipGitTasks) initArgs.push('--no-git-tasks');
    if (this.options.dryRun) initArgs.push('--dry-run');
    
    try {
      if (!this.options.dryRun) {
        // Try different command paths
        const commands = [
          'task-master',
          './node_modules/.bin/task-master',
          'npx task-master'
        ];
        
        let success = false;
        for (const cmd of commands) {
          try {
            execSync(`${cmd} ${initArgs.join(' ')}`, { 
              stdio: this.options.silent ? 'pipe' : 'inherit',
              cwd: targetDir 
            });
            success = true;
            break;
          } catch (e) {
            continue;
          }
        }
        
        if (!success) {
          throw new Error('Could not find task-master command');
        }
      } else {
        log.info(`Would run: task-master ${initArgs.join(' ')}`);
      }
      
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }
}

// Interactive prompts
class InteractivePrompt {
  static async prompt(question) {
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

  static async confirmContinue(message = 'Do you want to continue?') {
    const answer = await this.prompt(`${styles.yellow}${message} (Y/n): ${styles.reset}`);
    return answer.trim().toLowerCase() !== 'n';
  }

  static async selectInstallMethod() {
    console.log(`\n${styles.cyan}Select installation method:${styles.reset}`);
    console.log('1. NPM Global (recommended)');
    console.log('2. NPM Local (project-specific)');
    console.log('3. GitHub Latest Release');
    console.log('4. GitHub Source (latest development)');
    
    const answer = await this.prompt(`${styles.cyan}Enter choice (1-4): ${styles.reset}`);
    const choice = parseInt(answer.trim());
    
    const methods = [
      CONFIG.installMethods.NPM_GLOBAL,
      CONFIG.installMethods.NPM_LOCAL,
      CONFIG.installMethods.GITHUB_RELEASE,
      CONFIG.installMethods.GITHUB_SOURCE
    ];
    
    return methods[choice - 1] || CONFIG.installMethods.NPM_GLOBAL;
  }
}

// Display utilities
class Display {
  static banner() {
    console.clear();
    const banner = `
${styles.cyan}╔══════════════════════════════════════════════╗
║                                              ║
║         ${styles.bold}Task Master AI Installer${styles.reset}${styles.cyan}            ║
║                                              ║
║      ${styles.dim}Comprehensive Installation Tool${styles.reset}${styles.cyan}        ║
║                                              ║
╚══════════════════════════════════════════════╝${styles.reset}

${styles.dim}Version 2.0 - Advanced Installation Support${styles.reset}
`;
    console.log(banner);
  }

  static help() {
    console.log(`
${styles.bold}Task Master AI Advanced Installer${styles.reset}

${styles.cyan}Usage:${styles.reset} node install-taskmaster-advanced.js [options]

${styles.cyan}Options:${styles.reset}
  ${styles.green}-y, --yes${styles.reset}              Skip all prompts and use defaults
  ${styles.green}--method <type>${styles.reset}        Installation method:
                         npm-global, npm-local, github-release, github-source
  ${styles.green}--dry-run${styles.reset}              Show what would be done without making changes
  ${styles.green}--silent${styles.reset}               Suppress output (for automated installations)
  ${styles.green}--skip-install${styles.reset}         Skip package installation
  ${styles.green}--skip-init${styles.reset}            Skip project initialization
  ${styles.green}--no-aliases${styles.reset}           Skip shell alias setup
  ${styles.green}--no-git${styles.reset}               Skip git repository initialization
  ${styles.green}--no-git-tasks${styles.reset}         Don't store tasks in git
  ${styles.green}--rules <profiles...>${styles.reset}  Specify rule profiles to install
  ${styles.green}-h, --help${styles.reset}             Show this help message

${styles.cyan}Examples:${styles.reset}
  # Interactive installation
  node install-taskmaster-advanced.js

  # Quick global install
  node install-taskmaster-advanced.js --yes

  # Local project install
  node install-taskmaster-advanced.js --method npm-local

  # Install from GitHub with specific rules
  node install-taskmaster-advanced.js --method github-source --rules claude cursor

  # Dry run to preview
  node install-taskmaster-advanced.js --dry-run

${styles.cyan}Installation Methods:${styles.reset}
  ${styles.bold}npm-global${styles.reset}      Install globally via npm (recommended)
  ${styles.bold}npm-local${styles.reset}       Install locally in current project
  ${styles.bold}github-release${styles.reset}  Install from latest GitHub release
  ${styles.bold}github-source${styles.reset}   Install from GitHub source (development)

${styles.dim}For more information, visit: https://github.com/${CONFIG.githubRepo}${styles.reset}
`);
  }

  static systemCheckResults(checks) {
    console.log(`\n${styles.cyan}System Requirements Check:${styles.reset}`);
    
    const checkDisplay = (name, check) => {
      const icon = check.success ? '✅' : '❌';
      const color = check.success ? styles.green : styles.red;
      let message = `${icon} ${name}`;
      if (check.version) message += ` (${check.version})`;
      if (!check.success && check.message) message += ` - ${check.message}`;
      console.log(`${color}${message}${styles.reset}`);
    };

    checkDisplay('Node.js', checks.node);
    checkDisplay('npm', checks.npm);
    checkDisplay('Git', checks.git);
    checkDisplay('Internet', checks.internet);
    checkDisplay('Permissions', checks.permissions);
  }

  static installationSummary(summary) {
    console.log(`\n${styles.cyan}${styles.bold}Installation Summary:${styles.reset}`);
    console.log(`${styles.green}✅ Successful steps: ${summary.successful}${styles.reset}`);
    if (summary.failed > 0) {
      console.log(`${styles.red}❌ Failed steps: ${summary.failed}${styles.reset}`);
    }
    console.log(`${styles.dim}⏱️  Total time: ${summary.totalTime}s${styles.reset}`);
    
    if (summary.warnings.length > 0) {
      console.log(`\n${styles.yellow}Warnings:${styles.reset}`);
      summary.warnings.forEach(w => console.log(`  ${styles.yellow}⚠️  ${w}${styles.reset}`));
    }
    
    if (summary.errors.length > 0) {
      console.log(`\n${styles.red}Errors:${styles.reset}`);
      summary.errors.forEach(e => console.log(`  ${styles.red}❌ ${e}${styles.reset}`));
    }
  }

  static nextSteps(options) {
    console.log(`
${styles.green}${styles.bold}✨ Installation Complete!${styles.reset}

${styles.cyan}Quick Start Commands:${styles.reset}
${options.installMethod === CONFIG.installMethods.NPM_LOCAL ? 
  `  ${styles.dim}$${styles.reset} ${styles.bold}./task-master-local.js --help${styles.reset}` :
  `  ${styles.dim}$${styles.reset} ${styles.bold}task-master --help${styles.reset}`}
  ${styles.dim}$${styles.reset} ${styles.bold}task-master models --setup${styles.reset}
  ${styles.dim}$${styles.reset} ${styles.bold}task-master parse-prd .taskmaster/docs/prd.txt${styles.reset}

${styles.cyan}Next Steps:${styles.reset}

1. ${styles.bold}Configure AI models${styles.reset}
   ${styles.dim}Set up your preferred AI providers and API keys${styles.reset}

2. ${styles.bold}Create your PRD${styles.reset}
   ${styles.dim}Use the example template to define your project${styles.reset}

3. ${styles.bold}Generate tasks${styles.reset}
   ${styles.dim}Parse your PRD to create an actionable task list${styles.reset}

4. ${styles.bold}Start building${styles.reset}
   ${styles.dim}Use task-master to guide your development${styles.reset}

${styles.dim}Documentation: https://github.com/${CONFIG.githubRepo}${styles.reset}
${styles.dim}Need help? Run: ${options.installMethod === CONFIG.installMethods.NPM_LOCAL ? 
  './task-master-local.js --help' : 'task-master --help'}${styles.reset}
`);
  }
}

// Main orchestrator
async function main() {
  const args = process.argv.slice(2);
  
  // Parse options
  const options = {
    yes: args.includes('--yes') || args.includes('-y'),
    dryRun: args.includes('--dry-run'),
    silent: args.includes('--silent'),
    skipInstall: args.includes('--skip-install'),
    skipInit: args.includes('--skip-init'),
    skipAliases: args.includes('--no-aliases'),
    skipGit: args.includes('--no-git'),
    skipGitTasks: args.includes('--no-git-tasks'),
    rules: [],
    installMethod: null
  };
  
  // Parse installation method
  const methodIndex = args.findIndex(arg => arg === '--method');
  if (methodIndex !== -1 && args[methodIndex + 1]) {
    options.installMethod = args[methodIndex + 1];
  }
  
  // Parse rules
  const rulesIndex = args.findIndex(arg => arg === '--rules' || arg === '-r');
  if (rulesIndex !== -1) {
    let i = rulesIndex + 1;
    while (i < args.length && !args[i].startsWith('--')) {
      options.rules.push(args[i]);
      i++;
    }
  }
  
  // Show help
  if (args.includes('--help') || args.includes('-h')) {
    Display.help();
    process.exit(0);
  }
  
  // Initialize state
  const state = new InstallationState();
  
  // Setup installation steps
  state.addStep('Check system requirements');
  state.addStep('Install Task Master AI');
  state.addStep('Initialize project');
  state.addStep('Configure environment');
  
  // Display banner
  if (!options.silent) {
    Display.banner();
  }
  
  try {
    // Step 1: System checks
    state.startStep(0);
    const { allPassed, checks } = await SystemChecker.runAllChecks();
    
    if (!options.silent) {
      Display.systemCheckResults(checks);
    }
    
    if (!allPassed) {
      // Handle critical failures
      if (!checks.node.success || !checks.npm.success) {
        state.completeStep(0, 'failed');
        throw new Error('Critical system requirements not met');
      }
      
      // Handle warnings
      if (!checks.git.success) {
        state.addWarning('Git not available - some features will be disabled');
        options.skipGit = true;
      }
      
      if (!checks.internet.success && !options.skipInstall) {
        state.completeStep(0, 'failed');
        throw new Error('Internet connection required for installation');
      }
    }
    
    state.completeStep(0);
    
    // Get installation method if not provided
    if (!options.installMethod && !options.yes && !options.skipInstall) {
      options.installMethod = await InteractivePrompt.selectInstallMethod();
    } else if (!options.installMethod) {
      options.installMethod = CONFIG.installMethods.NPM_GLOBAL;
    }
    
    // Confirm before proceeding
    if (!options.yes && !options.silent) {
      const shouldContinue = await InteractivePrompt.confirmContinue(
        `Install Task Master AI using ${options.installMethod}?`
      );
      if (!shouldContinue) {
        console.log('Installation cancelled.');
        process.exit(0);
      }
    }
    
    // Step 2: Install package
    if (!options.skipInstall) {
      state.startStep(1);
      const installer = new Installer(options, state);
      const result = await installer.install(options.installMethod);
      
      if (!result.success) {
        state.completeStep(1, 'failed');
        state.addError(result.error);
        throw new Error(`Installation failed: ${result.error}`);
      }
      
      state.completeStep(1);
    } else {
      log.info('Skipping package installation');
    }
    
    // Step 3: Initialize project
    if (!options.skipInit) {
      state.startStep(2);
      const initializer = new ProjectInitializer(options, state);
      const result = await initializer.initialize();
      
      if (!result.success) {
        state.completeStep(2, 'failed');
        state.addError(result.error);
        throw new Error(`Project initialization failed: ${result.error}`);
      }
      
      state.completeStep(2);
    } else {
      log.info('Skipping project initialization');
    }
    
    // Step 4: Final configuration
    state.startStep(3);
    // Additional configuration steps could go here
    state.completeStep(3);
    
    // Display summary
    const summary = state.getSummary();
    
    if (!options.silent) {
      Display.installationSummary(summary);
      
      if (summary.failed === 0 && !options.dryRun) {
        Display.nextSteps(options);
      }
    }
    
    if (options.dryRun) {
      log.info('Dry run complete. No changes were made.');
    }
    
    process.exit(summary.failed > 0 ? 1 : 0);
    
  } catch (error) {
    log.error(`Installation failed: ${error.message}`);
    
    const summary = state.getSummary();
    if (!options.silent && summary.errors.length > 0) {
      console.log(`\n${styles.red}Error details:${styles.reset}`);
      summary.errors.forEach(e => console.log(`  ${styles.dim}•${styles.reset} ${e}`));
    }
    
    if (process.env.DEBUG) {
      console.error(error);
    }
    
    process.exit(1);
  }
}

// Handle uncaught errors
process.on('unhandledRejection', (error) => {
  log.error('Unexpected error occurred');
  console.error(error);
  process.exit(1);
});

// Run installer
main();