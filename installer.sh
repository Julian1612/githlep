#!/bin/bash
set -e

# ==============================================================================
#  GIT PROFESSIONAL SUITE INSTALLER
#  Syncs files from this repository to your system.
# ==============================================================================

# --- CONFIGURATION ---
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/git-suite"

# Installer-only colors
B='\033[1;34m'; G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'

echo -e "${B}🚀 SYNCING GIT SUITE...${N}"

# 1. VALIDATION
if [ ! -d "$REPO_ROOT/src" ] || [ ! -d "$REPO_ROOT/lib" ]; then
    echo -e "${Y}Error: Run this script from the repository root.${N}"
    echo "Expected folders 'src' and 'lib' not found."
    exit 1
fi

# 2. CREATE DIRECTORIES
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"

# 3. INSTALL SHARED LIBRARY
echo -ne "Updating Library... "
cp "$REPO_ROOT/lib/git-suite-lib.sh" "$BIN_DIR/"
chmod +x "$BIN_DIR/git-suite-lib.sh"
echo -e "${G}✔${N}"

# 4. INSTALL TOOLS
# Iterates through everything in src/ and copies it to bin/
for tool in "$REPO_ROOT/src"/*; do
    tool_name=$(basename "$tool")
    echo -ne "Updating $tool_name... "
    cp "$tool" "$BIN_DIR/$tool_name"
    chmod +x "$BIN_DIR/$tool_name"
    echo -e "${G}✔${N}"
done

# 5. INITIALIZE CONFIG (Only if missing)
# We do NOT overwrite existing configs to preserve your customization.
if [ ! -f "$CONFIG_DIR/aliases.conf" ]; then
    echo -e "${B}Creating default aliases...${N}"
    cat <<EOF > "$CONFIG_DIR/aliases.conf"
gh|Dashboard|~/.local/bin/gh
gcw|Smart Commit|~/.local/bin/gac
gps|Repo Switcher|~/.local/bin/rsw
gsw|Branch Switcher|~/.local/bin/gsw
gup|Smart Push|~/.local/bin/gpp
gbx|Branch Delete|~/.local/bin/gbd
gst|Stash Manager|~/.local/bin/gst
gundo|Revert|~/.local/bin/grc
gs|Status|git status -s
gl|Pull (Rebase)|git pull --rebase
EOF
fi

if [ ! -f "$CONFIG_DIR/repos.json" ]; then
    echo "[]" > "$CONFIG_DIR/repos.json"
fi

# 6. SHELL INTEGRATION
# Ensures the aliases are loaded in zshrc/bashrc
RC="$HOME/.zshrc"
[ ! -f "$RC" ] && RC="$HOME/.bashrc"
if ! grep -q "git_functions.zsh" "$RC"; then
    echo -e "\n# GIT SUITE" >> "$RC"
    echo "[ -f ~/.git_functions.zsh ] && source ~/.git_functions.zsh" >> "$RC"
    echo -e "${G}Linked in $RC${N}"
fi

# 7. APPLY CHANGES
# Regenerate the alias function file immediately based on current config
echo -ne "Applying Aliases... "
if [ -x "$BIN_DIR/gset" ]; then
    # We pipe 'q' to gset to make it generate the alias file and exit immediately
    "$BIN_DIR/gset" <<< "q" >/dev/null 2>&1 || true
    echo -e "${G}✔${N}"
else
    echo -e "${Y}Skipped (gset not found)${N}"
fi

echo -e "\n${B}✅ UPDATE COMPLETE.${N}"
echo -e "Restart your terminal to see changes."