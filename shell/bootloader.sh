#!/bin/bash
# -----------------------------------------------------------------------------
# LAYER 4: THE BOOTLOADER
# Initialisiert die Umgebung, lädt DNA und injiziert Adapter.
# -----------------------------------------------------------------------------

# Ermittle den absoluten Pfad zum Repo-Root (wo auch immer das Skript liegt)
# Wir gehen davon aus, dass bootloader.sh in /shell/ liegt -> also ../
LCP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 1. LOAD DNA (Configuration & Constants)
if [ -f "$LCP_ROOT/dna/config.sh" ]; then
    source "$LCP_ROOT/dna/config.sh"
else
    echo "CRITICAL ERROR: DNA not found in $LCP_ROOT/dna/config.sh"
    exit 1
fi

# 2. INJECT ADAPTERS (Capabilities)
# Wir laden die Adapter sicher. Wenn einer fehlt, warnen wir (oder brechen ab).
for adapter in ui git fs; do
    if [ -f "$LCP_ROOT/adapters/${adapter}.sh" ]; then
        source "$LCP_ROOT/adapters/${adapter}.sh"
    fi
done

# 3. INITIALIZE RUNTIME
# Farben laden (definiert in DNA)
load_theme_colors

# @Intent: Global Exit Trap for Cleanup (Cursor reset, Temp files)
cleanup() {
    tput cnorm 2>/dev/null # Cursor wieder einblenden
    tput sgr0  2>/dev/null # Farben zurücksetzen
}
trap cleanup EXIT

# @Intent: Führt ein Core-Modul aus und injiziert Abhängigkeiten
# @Input: $1 (Modul-Name ohne Pfad/Endung), $@ (Argumente)
lcp_run() {
    local module="$1"
    shift
    
    local core_path="$LCP_ROOT/core/${module}.sh"
    
    if [ -f "$core_path" ]; then
        source "$core_path"
        # Konvention: Jedes Core-Modul muss eine Funktion '${module}_main' haben
        if type "${module}_main" >/dev/null 2>&1; then
            "${module}_main" "$@"
        else
            echo "${C_RED}${SYM_ERR} Error: Entry point '${module}_main' missing in $core_path${RESET}"
            exit 1
        fi
    else
        echo "${C_RED}${SYM_ERR} System Error: Core module '$module' not found.${RESET}"
        exit 1
    fi
}
