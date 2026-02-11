#!/bin/bash
# -----------------------------------------------------------------------------
# LAYER 0: THE DNA
# Single Source of Truth für Konfiguration, Konstanten und Theme.
# -----------------------------------------------------------------------------

# [SYSTEM METADATA]
export LCP_VERSION="3.0.0"
export LCP_DEBUG="false"

# [THEME DEFINITION]
# Wir nutzen Tput Indizes für maximale Kompatibilität
# 1=Red, 2=Green, 3=Yellow, 4=Blue, 5=Magenta, 6=Cyan, 7=White, 8=Grey
export C_PRIMARY_IDX=6      # Cyan (Hauptfokus)
export C_SECONDARY_IDX=4    # Blue (Rahmen/Struktur)
export C_SUCCESS_IDX=2      # Green (Erfolg)
export C_DANGER_IDX=1       # Red (Fehler/Löschen)
export C_WARN_IDX=3         # Yellow (Warnung)
export C_MUTED_IDX=8        # Grey (Metadaten/Linien)

# [SYMBOLS & ICONS]
# Fallback-sichere Icons (Nerd Fonts empfohlen, aber nicht zwingend)
export SYM_SEP="|"
export SYM_ARROW="➜"
export SYM_SELECT="❯"
export SYM_OK="✔"
export SYM_ERR="✖"
export SYM_WARN="⚠"
export SYM_LIGHTNING="⚡"
export SYM_LOCK="🔒"
export SYM_EDIT="✎"

# [BEHAVIOR FLAGS]
# Pager Flags für 'less' (F=quit if one screen, R=raw colors, X=no init clear)
export PAGER_FLAGS="-F -R -X"

# [EDITOR PREFERENCE]
# Versucht erst VS Code, dann Nano, dann Vi
export EDITOR_DEFAULT="nano"

# @Intent: Lädt Farben dynamisch basierend auf Terminal-Capabilities
# @output: Exportiert C_* Variablen
load_theme_colors() {
    # Defaults (falls kein TTY)
    export C_RESET=""
    export C_BOLD=""
    
    if [ -t 1 ]; then
        local colors
        colors=$(tput colors 2>/dev/null || echo 8)
        
        if [ "$colors" -ge 8 ]; then
            export C_RESET=$(tput sgr0)
            export C_BOLD=$(tput bold)
            
            export C_MAIN=$(tput setaf "$C_PRIMARY_IDX")
            export C_ACCENT=$(tput setaf "$C_SECONDARY_IDX")
            export C_GREEN=$(tput setaf "$C_SUCCESS_IDX")
            export C_RED=$(tput setaf "$C_DANGER_IDX")
            export C_YELLOW=$(tput setaf "$C_WARN_IDX")
            
            # Smart Muted Color (256 Colors vs 8 Colors)
            if [ "$colors" -ge 256 ]; then
                export C_MUTED=$(tput setaf 240) # Dunkelgrau
            else
                export C_MUTED=$(tput setaf "$C_MUTED_IDX")
            fi
        fi
    fi
}
