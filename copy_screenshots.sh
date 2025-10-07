#!/bin/bash

# Script to copy screenshots to repository

echo "Copying screenshots to repository..."

# Source directory
SRC="/Users/harshilpatel/Desktop/Projects/MCP/screenshots"

# Destination directory
DEST="/Users/harshilpatel/Desktop/Projects/MCP/ottostudio/__beta_testing/docs/screenshots"

# Copy files
cp "$SRC/main_menu.png" "$DEST/"
cp "$SRC/printer_selection.png" "$DEST/"
cp "$SRC/profile_selection.png" "$DEST/"
cp "$SRC/job_setup_and_rack_validation.png" "$DEST/"
cp "$SRC/Automation_sequence.jpeg" "$DEST/"
cp "$SRC/Ottomat3d-Logo.png" "$DEST/"

# Also copy the icon and iconset to project root (for potential use)
cp "$SRC/OTTOMAT3D.icns" "/Users/harshilpatel/Desktop/Projects/MCP/ottostudio/__beta_testing/"
cp -r "$SRC/OTTOMAT3D.iconset" "/Users/harshilpatel/Desktop/Projects/MCP/ottostudio/__beta_testing/"

echo "✅ Done! All screenshots copied."
echo ""
echo "Files copied:"
ls -lh "$DEST"
