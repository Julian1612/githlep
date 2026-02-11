#!/bin/bash
# -----------------------------------------------------------------------------
# LAYER 2: UI ADAPTER
# Implementiert die visuellen Schnittstellen (Dumb Painter).
# -----------------------------------------------------------------------------

# @Intent: Löscht den Bildschirminhalt vollständig
ui_clear() {
    printf "\033[H\033[J"
}

# @Intent: Zeichnet den Standard-Header mit Box-Drawing-Zeichen
# @Input: $1 (Titel), $2 (Untertitel/Info)
ui_header() {
    local title="$1"
    local info="$2"
    
    # Box Drawing Chars (Definiert in DNA oder Fallback)
    local TL="╭" TR="╮" BL="╰" BR="╯" H="─" V="│"
    
    ui_clear
    local width=60
    # Berechne Füllzeichen
    local content_len=$((${#title} + ${#info} + 3)) # +3 für Leerzeichen/Abstände
    local filler_len=$((width - content_len - 2))  # -2 für Ränder
    
    local filler=""; for ((i=0; i<filler_len; i++)); do filler+=" "; done
    local line=""; for ((i=0; i<width; i++)); do line+="$H"; done

    # Render Header
    printf "${C_ACCENT}%s%s%s${C_RESET}\n" "$TL" "$line" "$TR"
    printf "${C_ACCENT}%s${C_RESET} ${C_BOLD}${C_MAIN}%s${C_RESET} ${C_MUTED}%s${C_RESET}%s${C_ACCENT}%s${C_RESET}\n" \
           "$V" "$title" "$info" "$filler" "$V"
    printf "${C_ACCENT}%s%s%s${C_RESET}\n" "$BL" "$line" "$BR"
    printf "\n"
}

# @Intent: Zeigt ein Listenelement an (Selectable)
# @Input: $1(Label) $2(Info) $3(IsSelected: true/false) $4(IsActive: true/false)
ui_item() {
    local label="$1"
    local info="$2"
    local is_sel="$3"
    local is_act="$4"
    
    local prefix="   "
    local c_lbl="${C_RESET}"
    local c_inf="${C_MUTED}"
    
    # State: Active (z.B. aktueller Branch)
    if [ "$is_act" == "true" ]; then
        label="${label} (Active)"
        c_lbl="${C_MAIN}${C_BOLD}"
    fi
    
    # State: Selected (Cursor)
    if [ "$is_sel" == "true" ]; then
        prefix=" ${C_GREEN}${SYM_SELECT} "
        c_lbl="${C_GREEN}${C_BOLD}"
        c_inf="${C_GREEN}"
    fi

    # Kürze Info, falls zu lang
    if [ ${#info} -gt 30 ]; then info="...${info: -27}"; fi

    printf "${prefix}%-30b %s%s${C_RESET}\n" "${c_lbl}${label}" "${c_inf}" "$info"
}

# @Intent: Zeigt eine temporäre Statusmeldung (Toast)
# @Input: $1 (Nachricht), $2 (Typ: info, success, error)
ui_status() {
    local msg="$1"
    local type="${2:-info}" 
    
    tput civis 2>/dev/null
    case "$type" in
        "success") printf "\n ${C_GREEN}${SYM_OK} %s${C_RESET}\n" "$msg" ;;
        "error")   printf "\n ${C_RED}${SYM_ERR} %s${C_RESET}\n" "$msg" ;;
        "warn")    printf "\n ${C_YELLOW}${SYM_WARN} %s${C_RESET}\n" "$msg" ;;
        *)         printf "\n ${C_MAIN}${SYM_ARROW} %s${C_RESET}\n" "$msg" ;;
    esac
    sleep 0.8
    tput civis 2>/dev/null
}

# @Intent: Wrapper für User-Input
# @Input: $1 (Prompt Text)
# @Output: Setzt globale Variable $UI_VAL
ui_input() {
    local prompt="$1"
    tput cnorm 2>/dev/null
    printf "\n ${C_MAIN}${SYM_ARROW}${C_RESET} %s " "$prompt"
    read -r UI_VAL
    tput civis 2>/dev/null
}
