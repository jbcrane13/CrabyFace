#!/bin/bash

# Find the most recent backup
echo "🔍 Looking for backup files..."
LATEST_BACKUP=$(ls -t JubileeMobileBay.xcodeproj/project.pbxproj.backup_* 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ No backup files found!"
    exit 1
fi

echo "✅ Found backup: $LATEST_BACKUP"
echo ""
echo "⚠️  This will restore the project file from the backup."
echo "   Current (broken) project file will be overwritten."
echo ""
read -p "Continue? (yes/no): " response

if [ "$response" != "yes" ]; then
    echo "❌ Cancelled."
    exit 0
fi

# Create a backup of the broken file just in case
cp JubileeMobileBay.xcodeproj/project.pbxproj JubileeMobileBay.xcodeproj/project.pbxproj.broken

# Restore from backup
cp "$LATEST_BACKUP" JubileeMobileBay.xcodeproj/project.pbxproj

echo "✅ Restored from backup!"
echo "   Broken file saved as: project.pbxproj.broken"
echo ""
echo "📋 Next steps:"
echo "   1. Open Xcode"
echo "   2. Clean Build Folder (⇧⌘K)"
echo "   3. Try building again"