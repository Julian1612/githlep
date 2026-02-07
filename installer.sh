#!/bin/bash
set -e

# ==============================================================================
#  GIT SUITE INSTALLER - UPDATE & CLEANUP
# ==============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONF_DIR="$HOME/.config/git-suite"
LOADER_SCRIPT="$CONF_DIR/loader.sh"

G='\033[0;32m'; B='\033[1;34m'; R='\033[0;31m'; N='\033[0m'

# Shell Erkennung
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" = "zsh" ]; then RC_FILE="$HOME/.zshrc"
elif [ "$CURRENT_SHELL" = "bash" ]; then RC_FILE="$HOME/.bashrc"
else [ -f "$HOME/.zshrc" ] && RC_FILE="$HOME/.zshrc" || RC_FILE="$HOME/.bashrc"; fi

echo -e "${B}🔄 Aktualisiere Git Suite...${N}"

mkdir -p "$BIN_DIR"
mkdir -p "$CONF_DIR"

# 1. Dateien kopieren
cp "$REPO_ROOT/lib/git-suite-lib.sh" "$BIN_DIR/"
cp "$REPO_ROOT/src/"* "$BIN_DIR/"
chmod +x "$BIN_DIR/"*

# 2. Config neu schreiben (gbx entfernt!)
cat <<CONFIG > "$CONF_DIR/aliases.conf"
# --- CORE SUITE ---
gh|Dashboard|$BIN_DIR/gh
gset|Einstellungen|$BIN_DIR/gset
gps|Repo Switcher|$BIN_DIR/rsw
gsw|Branch Manager|$BIN_DIR/gsw
gcw|Smart Commit|$BIN_DIR/gac
gup|Push & PR|$BIN_DIR/gpp
gst|Stash Manager|$BIN_DIR/gst
gundo|Revert Commit|$BIN_DIR/grc

# --- WRAPPERS ---
gs|Status|git status -s
gl|Pull|git pull --rebase
CONFIG

# 3. Loader neu bauen
echo "# GIT SUITE LOADER" > "$LOADER_SCRIPT"
echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$LOADER_SCRIPT"
[ -f "$CONF_DIR/settings.conf" ] && cat "$CONF_DIR/settings.conf" >> "$LOADER_SCRIPT"

while IFS='|' read -r short name cmd; do
    [[ "$short" =~ ^#.* || -z "$short" ]] && continue
    echo "unalias $short >/dev/null 2>&1" >> "$LOADER_SCRIPT"
    echo "alias $short='$cmd'" >> "$LOADER_SCRIPT"
done < "$CONF_DIR/aliases.conf"

chmod +x "$LOADER_SCRIPT"

# 4. Verknüpfung prüfen
if ! grep -q "git-suite/loader.sh" "$RC_FILE"; then
    echo "[ -f \"$LOADER_SCRIPT\" ] && source \"$LOADER_SCRIPT\"" >> "$RC_FILE"
fi

echo -e "${G}✅ Update fertig!${N}"
echo -e "${R}WICHTIG: Alte 'gbd' Datei wird jetzt gelöscht.${N}"
rm -f "$BIN_DIR/gbd" "src/gbd" 2>/dev/null || true

echo -e "Bitte Shell neu laden:"
echo -e "${B}source $RC_FILE${N}"
