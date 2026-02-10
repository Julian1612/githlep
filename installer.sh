#!/bin/bash
set -e
G='\033[0;32m'; B='\033[1;34m'; N='\033[0m'
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONF_DIR="$HOME/.config/git-suite"
LOADER="$CONF_DIR/loader.sh"
ALIAS_CONF="$CONF_DIR/aliases.conf"

echo -e "${B}🚀 Installing Git Suite...${N}"
mkdir -p "$BIN_DIR" "$CONF_DIR"

# Copy Lib
if [ -f "$REPO_ROOT/lib/git-suite-lib.sh" ]; then
    cp "$REPO_ROOT/lib/git-suite-lib.sh" "$BIN_DIR/"
else
    echo "Warning: lib not found locally."
fi

# Copy Tools
for tool in gh gpc gps gsw gcw gst gset; do
    if [ -f "$REPO_ROOT/$tool" ]; then
        cp "$REPO_ROOT/$tool" "$BIN_DIR/"
        chmod +x "$BIN_DIR/$tool"
    fi
done

# Config Aliases
if [ ! -s "$ALIAS_CONF" ]; then
cat <<CONFIG > "$ALIAS_CONF"
# DASHBOARD
gh|Control Center|gh
# TOOLS
create|New Project|gpc new
class|New Class|gpc -c
gps|Repo Switcher|gps
gsw|Branch Manager|gsw
gcw|Commit Wizard|gcw
gst|Stash Manager|gst
gset|Settings|gset
CONFIG
fi

# Loader
cat <<LOAD > "$LOADER"
export PATH="$BIN_DIR:\$PATH"
[ -f "$CONF_DIR/settings.conf" ] && source "$CONF_DIR/settings.conf"
if [ -f "$ALIAS_CONF" ]; then
    while IFS='|' read -r short name cmd; do
        [[ "\$short" =~ ^# || -z "\$short" ]] && continue
        unalias "\$short" >/dev/null 2>&1
        alias \$short='\$cmd'
    done < "$ALIAS_CONF"
fi
LOAD
chmod +x "$LOADER"

# Shell Integration
RC="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && RC="$HOME/.bashrc"
if ! grep -q "git-suite/loader.sh" "$RC"; then
    echo "" >> "$RC"
    echo "[ -f \"$LOADER\" ] && source \"$LOADER\"" >> "$RC"
fi

echo -e "${G}✅ Installed.${N} Restart terminal or run: source $RC"
