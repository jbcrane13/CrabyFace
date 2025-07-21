#!/usr/bin/env python3
"""
Xcode Project Duplicate File Reference Cleanup Script
Safely removes duplicate file references from project.pbxproj

Based on lessons learned:
- Always create backups before modifying project files
- Preserve file ordering and structure
- Validate changes before writing
- Provide detailed logging for debugging
"""

import re
import os
import sys
import shutil
from datetime import datetime
from collections import defaultdict, OrderedDict

def create_backup(project_file):
    """Create timestamped backup of project file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{project_file}.backup_{timestamp}"
    shutil.copy2(project_file, backup_path)
    print(f"✅ Created backup: {backup_path}")
    return backup_path

def parse_file_references(content):
    """Parse all file references with their UUIDs and contexts"""
    # Pattern to match file references: UUID /* filename */
    file_pattern = r'([A-F0-9]{24})\s*/\*\s*([^*]+\.(swift|m|h|storyboard|xib))\s*\*/'
    
    file_refs = []
    for match in re.finditer(file_pattern, content):
        uuid = match.group(1)
        filename = match.group(2)
        # Find the line number for context
        line_start = content.rfind('\n', 0, match.start()) + 1
        line_num = content[:line_start].count('\n') + 1
        file_refs.append({
            'uuid': uuid,
            'filename': filename,
            'line': line_num,
            'full_match': match.group(0)
        })
    
    return file_refs

def find_file_sections(lines):
    """Find where each UUID appears in different sections"""
    sections = {
        'PBXBuildFile': [],
        'PBXFileReference': [],
        'PBXGroup': [],
        'PBXSourcesBuildPhase': [],
        'PBXResourcesBuildPhase': []
    }
    
    current_section = None
    for i, line in enumerate(lines):
        # Detect section starts
        for section in sections:
            if f"/* Begin {section} section */" in line:
                current_section = section
            elif f"/* End {section} section */" in line:
                current_section = None
        
        if current_section:
            sections[current_section].append(i)
    
    return sections

def analyze_duplicates(file_refs):
    """Analyze which files have duplicates and determine which to keep"""
    file_groups = defaultdict(list)
    
    for ref in file_refs:
        file_groups[ref['filename']].append(ref)
    
    duplicates = {}
    for filename, refs in file_groups.items():
        if len(refs) > 1:
            # Sort by line number - keep the first occurrence
            refs.sort(key=lambda x: x['line'])
            duplicates[filename] = {
                'keep': refs[0],
                'remove': refs[1:]
            }
    
    return duplicates

def get_uuid_dependencies(content, uuid):
    """Find all lines that reference a given UUID"""
    lines = content.split('\n')
    dependent_lines = []
    
    for i, line in enumerate(lines):
        if uuid in line:
            dependent_lines.append(i)
    
    return dependent_lines

def remove_duplicate_references(content, duplicates):
    """Remove duplicate file references and all their associated entries"""
    lines = content.split('\n')
    sections = find_file_sections(lines)
    
    # Collect all UUIDs to remove
    uuids_to_remove = set()
    for filename, dup_info in duplicates.items():
        for ref in dup_info['remove']:
            uuids_to_remove.add(ref['uuid'])
    
    # Track lines to remove
    lines_to_remove = set()
    
    # Find all lines containing UUIDs to remove
    for uuid in uuids_to_remove:
        for i, line in enumerate(lines):
            if uuid in line:
                lines_to_remove.add(i)
    
    # Create filtered content
    filtered_lines = []
    removed_count = 0
    
    for i, line in enumerate(lines):
        if i in lines_to_remove:
            print(f"  Removing line {i + 1}: {line.strip()[:80]}...")
            removed_count += 1
        else:
            filtered_lines.append(line)
    
    return '\n'.join(filtered_lines), removed_count

def validate_project_file(content):
    """Basic validation to ensure project file structure is intact"""
    required_sections = [
        '/* Begin PBXBuildFile section */',
        '/* End PBXBuildFile section */',
        '/* Begin PBXFileReference section */',
        '/* End PBXFileReference section */',
        '/* Begin PBXGroup section */',
        '/* End PBXGroup section */',
        '/* Begin PBXProject section */',
        '/* End PBXProject section */'
    ]
    
    for section in required_sections:
        if section not in content:
            return False, f"Missing required section: {section}"
    
    # Check that braces are balanced
    open_braces = content.count('{')
    close_braces = content.count('}')
    if open_braces != close_braces:
        return False, f"Unbalanced braces: {open_braces} open, {close_braces} close"
    
    return True, "OK"

def main():
    # Path to your project file
    project_file = "JubileeMobileBay.xcodeproj/project.pbxproj"
    
    if not os.path.exists(project_file):
        print(f"❌ Error: Project file not found: {project_file}")
        print("Please run this script from the project root directory.")
        sys.exit(1)
    
    print("🔍 Xcode Project Duplicate File Reference Cleanup")
    print("=" * 50)
    
    # Step 1: Create backup
    backup_path = create_backup(project_file)
    
    # Step 2: Read the file
    print("\n📖 Reading project file...")
    with open(project_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Step 3: Parse file references
    print("\n🔎 Analyzing file references...")
    file_refs = parse_file_references(content)
    print(f"  Found {len(file_refs)} total file references")
    
    # Step 4: Find duplicates
    duplicates = analyze_duplicates(file_refs)
    
    if not duplicates:
        print("\n✅ No duplicate file references found!")
        return
    
    print(f"\n⚠️  Found {len(duplicates)} files with duplicate references:")
    for filename, dup_info in sorted(duplicates.items()):
        print(f"  - {filename}: {len(dup_info['remove']) + 1} references (keeping first)")
    
    # Step 5: Ask for confirmation
    print(f"\n❓ This will remove {sum(len(d['remove']) for d in duplicates.values())} duplicate references.")
    response = input("Continue? (yes/no): ").strip().lower()
    
    if response != 'yes':
        print("\n❌ Cancelled by user.")
        return
    
    # Step 6: Remove duplicates
    print("\n🧹 Removing duplicate references...")
    cleaned_content, removed_count = remove_duplicate_references(content, duplicates)
    print(f"  Removed {removed_count} lines")
    
    # Step 7: Validate cleaned content
    print("\n✔️  Validating cleaned project file...")
    is_valid, message = validate_project_file(cleaned_content)
    
    if not is_valid:
        print(f"❌ Validation failed: {message}")
        print(f"   Backup preserved at: {backup_path}")
        return
    
    # Step 8: Write cleaned content
    print("\n💾 Writing cleaned project file...")
    with open(project_file, 'w', encoding='utf-8') as f:
        f.write(cleaned_content)
    
    print("\n✅ Success! Duplicate references removed.")
    print(f"   Backup saved at: {backup_path}")
    print("\n📋 Next steps:")
    print("   1. Open Xcode")
    print("   2. Clean Build Folder (⇧⌘K)")
    print("   3. Build the project (⌘B)")
    print("\n⚠️  If anything goes wrong, restore from backup:")
    print(f"   cp {backup_path} {project_file}")

if __name__ == "__main__":
    main()