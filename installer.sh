#!/bin/bash
set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONF_DIR="$HOME/.config/git-suite"
LOADER="$CONF_DIR/loader.sh"
G='\033[0;32m'; B='\033[1;34m'; N='\033[0m'

# Shell Check
SH=$(basename "$SHELL")
if [ "$SH" = "zsh" ]; then RC="$HOME/.zshrc"
elif [ "$SH" = "bash" ]; then RC="$HOME/.bashrc"
else [ -f "$HOME/.zshrc" ] && RC="$HOME/.zshrc" || RC="$HOME/.bashrc"; fi

echo -e "${B}🚀 Syncing Repo -> System...${N}"
mkdir -p "$BIN_DIR" "$CONF_DIR"

# 1. Copy Files
cp "$REPO_ROOT/lib/git-suite-lib.sh" "$BIN_DIR/"
cp "$REPO_ROOT/src/"* "$BIN_DIR/"
chmod +x "$BIN_DIR/"*

# 2. Config (Aliase setzen)
cat <<CONFIG > "$CONF_DIR/aliases.conf"
# CORE
gh|Dashboard|$BIN_DIR/gh
gset|Settings|$BIN_DIR/gset
gps|Repo Switcher|$BIN_DIR/gps
gsw|Branch Manager|$BIN_DIR/gsw

# COMMIT SUITE
gcw|Smart Commit|$BIN_DIR/gcw
gup|Push & PR|$BIN_DIR/gcw -p
gundo|Revert|$BIN_DIR/gcw -r
gst|Stash|$BIN_DIR/gst

# GIT BASICS
gs|Status|git status -s
gl|Pull|git pull --rebase
CONFIG

# 3. Loader
echo "# GIT SUITE LOADER" > "$LOADER"
echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$LOADER"
[ -f "$CONF_DIR/settings.conf" ] && cat "$CONF_DIR/settings.conf" >> "$LOADER"
while IFS='|' read -r short name cmd; do
    [[ "$short" =~ ^# || -z "$short" ]] && continue
    echo "unalias $short >/dev/null 2>&1" >> "$LOADER"
    echo "alias $short='$cmd'" >> "$LOADER"
done < "$CONF_DIR/aliases.conf"
chmod +x "$LOADER"

# 4. Link
if ! grep -q "git-suite/loader.sh" "$RC"; then
    echo "[ -f \"$LOADER\" ] && source \"$LOADER\"" >> "$RC"
fi

# 5. Cleanup System
rm -f "$BIN_DIR/gac" "$BIN_DIR/gpp" "$BIN_DIR/grc" "$BIN_DIR/gbd" "$BIN_DIR/rsw" 2>/dev/null || true

echo -e "${G}✅ Updated.${N} Reload shell: ${B}source $RC${N}"
