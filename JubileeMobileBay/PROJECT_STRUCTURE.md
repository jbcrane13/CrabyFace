# Project Structure Guide

## Root Directory Organization

This project follows a standardized folder structure to maintain organization and clarity. All new files should be placed in their appropriate directories as outlined below.

```
CrabyFace/
├── Documents/               # All project documentation
│   ├── Development/         # Development guides and lessons
│   │   ├── lessonslearned.md
│   │   ├── INSTALLER_README.md
│   │   └── TaskMaster_claude.md
│   ├── CloudKit/           # CloudKit schema and documentation
│   │   ├── cloudkit_schema_json.json
│   │   ├── cloudkit_schema_table.md
│   │   └── CloudKit Schema - Record Types and Fields.pdf
│   └── Requirements/       # Project requirements and PRDs
│
├── Scripts/                # All executable scripts
│   ├── Installation/       # Setup and installation scripts
│   │   ├── install.sh
│   │   ├── install-taskmaster.sh
│   │   ├── install-taskmaster.js
│   │   ├── install-taskmaster-advanced.js
│   │   └── test-installers.sh
│   ├── Testing/           # Test automation scripts
│   └── Utilities/         # Helper scripts and tools
│
├── Screenshots/           # App screenshots and UI captures
│
├── Archives/              # Old files, logs, and backups
│   └── crashlog.txt
│
├── JubileeMobileBay/      # Main iOS project directory
│   ├── JubileeMobileBay.xcodeproj/
│   ├── JubileeMobileBay/
│   ├── JubileeMobileBayTests/
│   ├── JubileeMobileBayUITests/
│   ├── ADD_FILES_TO_XCODE.md
│   ├── ADD_FILES_TO_XCODE_UPDATED.md
│   ├── BUILD_STATUS.md
│   └── [project-specific files]
│
├── CLAUDE.md              # Claude-specific instructions (root level)
├── GEMINI.md              # Gemini-specific instructions (root level)
├── README.md              # Main project README (root level)
└── PROJECT_STRUCTURE.md   # This file (root level)
```

## File Placement Guidelines

### When creating new files:

1. **Documentation Files** (.md, .txt, .pdf)
   - Development guides → `Documents/Development/`
   - CloudKit related → `Documents/CloudKit/`
   - Requirements/PRDs → `Documents/Requirements/`
   - Build status → Keep in project folder (e.g., `JubileeMobileBay/BUILD_STATUS.md`)

2. **Scripts** (.sh, .js, .py, .applescript)
   - Installation/setup → `Scripts/Installation/`
   - Testing scripts → `Scripts/Testing/`
   - Utility scripts → `Scripts/Utilities/`

3. **Screenshots and Media**
   - App screenshots → `Screenshots/`
   - Demo videos → Keep in project folder if project-specific
   - Large media files → Consider using Git LFS

4. **Temporary Files and Logs**
   - Crash logs → `Archives/`
   - Old versions → `Archives/`
   - Backup files → `Archives/`

5. **Project-Specific Files**
   - Keep in the relevant project directory
   - Example: iOS project files stay in `JubileeMobileBay/`

## Special Files (Always at Root)

These files should always remain at the root level:
- `README.md` - Main project documentation
- `CLAUDE.md` - Claude AI instructions
- `GEMINI.md` - Gemini AI instructions  
- `PROJECT_STRUCTURE.md` - This structure guide
- `.gitignore` - Git ignore rules
- `.env` - Environment variables (if used)

## Creating New Projects

When adding a new project to this repository:
1. Create a new directory at the root level with the project name
2. Follow the same internal structure as JubileeMobileBay
3. Keep project-specific documentation within the project folder
4. Share common resources using the root-level folders

## Maintenance

To keep the project organized:
1. Run the `/organize` command periodically to auto-organize misplaced files
2. Review and archive old files quarterly
3. Update this guide when adding new folder categories