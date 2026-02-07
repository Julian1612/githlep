#!/bin/bash
set -e

# ==============================================================================
#  GIT SUITE INSTALLER (FINAL ROBUST VERSION)
# ==============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONF_DIR="$HOME/.config/git-suite"
LOADER_SCRIPT="$CONF_DIR/loader.sh"
RC_FILE="$HOME/.zshrc"
[ ! -f "$RC_FILE" ] && RC_FILE="$HOME/.bashrc"

G='\033[0;32m'; B='\033[1;34m'; N='\033[0m'

echo -e "${B}🚀 Installiere Git Suite...${N}"

mkdir -p "$BIN_DIR"
mkdir -p "$CONF_DIR"

# 1. Dateien kopieren
echo -ne "Kopiere Skripte... "
cp "$REPO_ROOT/lib/git-suite-lib.sh" "$BIN_DIR/"
cp "$REPO_ROOT/src/"* "$BIN_DIR/"
chmod +x "$BIN_DIR/"*
echo -e "${G}Fertig${N}"

# 2. Config initialisieren (Falls fehlt)
if [ ! -f "$CONF_DIR/aliases.conf" ]; then
    echo "Erstelle Standard-Aliase..."
    cat <<EOF > "$CONF_DIR/aliases.conf"
gh|Dashboard|~/.local/bin/gh
gset|Einstellungen|~/.local/bin/gset
gps|Repo Switcher|~/.local/bin/rsw
gsw|Branch Switcher|~/.local/bin/gsw
gcw|Smart Commit|~/.local/bin/gac
gup|Push & PR|~/.local/bin/gpp
gst|Stash Manager|~/.local/bin/gst
gbx|Branch Delete|~/.local/bin/gbd
gundo|Revert Commit|~/.local/bin/grc
gs|Status|git status -s
gl|Pull|git pull --rebase
EOF
fi

# 3. Loader Script generieren (MIT UNALIAS FIX)
echo "# GIT SUITE LOADER" > "$LOADER_SCRIPT"
echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$LOADER_SCRIPT"

# Lade auch Settings falls vorhanden
[ -f "$CONF_DIR/settings.conf" ] && cat "$CONF_DIR/settings.conf" >> "$LOADER_SCRIPT"

while IFS='|' read -r short name cmd; do
    [[ "$short" =~ ^#.* || -z "$short" ]] && continue
    # Der Konflikt-Fix:
    echo "unalias $short >/dev/null 2>&1" >> "$LOADER_SCRIPT"
    echo "alias $short='$cmd'" >> "$LOADER_SCRIPT"
done < "$CONF_DIR/aliases.conf"

chmod +x "$LOADER_SCRIPT"

# 4. Shell Verknüpfung
echo -ne "Verknüpfe mit $RC_FILE... "
if ! grep -q "git-suite/loader.sh" "$RC_FILE"; then
    echo "" >> "$RC_FILE"
    echo "[ -f \"$LOADER_SCRIPT\" ] && source \"$LOADER_SCRIPT\"" >> "$RC_FILE"
    echo -e "${G}Hinzugefügt${N}"
else
    echo -e "${B}Bereits aktiv${N}"
fi

echo -e "\n${G}✅ SYSTEM AKTUALISIERT.${N}"
echo -e "Deine Quell-Dateien sind jetzt auf dem neuesten Stand."