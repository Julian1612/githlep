#!/bin/bash
# -----------------------------------------------------------------------------
# GIT SUITE CORE v9 (Dynamic Engine)
# -----------------------------------------------------------------------------

CONFIG_DIR="$HOME/.config/git-suite"
THEME_CONF="$CONFIG_DIR/theme.conf"
SETTINGS_CONF="$CONFIG_DIR/settings.conf"

# --- 1. DEFAULTS (Soft Init for Live Preview) ---
# We check if variables are already set (by gset) before overwriting
if [ -f "$SETTINGS_CONF" ]; then source "$SETTINGS_CONF"; fi
GIT_EDITOR="${GIT_EDITOR:-vim}"

# Theme Defaults
: "${C_BORDER_IDX:=4}"   # Blue
: "${C_TITLE_IDX:=6}"    # Cyan
: "${C_SEL_IDX:=2}"      # Green
: "${C_TEXT_IDX:=7}"     # White
: "${C_MUTED_IDX:=8}"    # Gray
: "${UI_STYLE:=rounded}" # rounded, double, heavy, ascii
: "${UI_PROMPT:=❯}"      # Selector symbol

# Load User Theme (Only if not in preview mode)
if [ -z "$PREVIEW_MODE" ] && [ -f "$THEME_CONF" ]; then source "$THEME_CONF"; fi

# --- 2. COLOR INITIALIZATION ---
if [ -t 1 ]; then
    COLORS=$(tput colors 2>/dev/null || echo 8)
    if [ "$COLORS" -ge 8 ]; then
        BOLD=$(tput bold); RESET=$(tput sgr0)
        
        # We construct colors dynamically based on current indices
        C_BORDER=$(tput setaf "$C_BORDER_IDX")
        C_TITLE=$(tput setaf "$C_TITLE_IDX")
        C_SEL=$(tput setaf "$C_SEL_IDX")
        C_TEXT=$(tput setaf "$C_TEXT_IDX")
        
        if [ "$COLORS" -ge 256 ]; then
            C_MUTED=$(tput setaf 240)
        else
            C_MUTED=$(tput setaf "$C_MUTED_IDX" 2>/dev/null || tput setaf 0)
        fi
        
        C_RED=$(tput setaf 1); C_GREEN=$(tput setaf 2); C_YELLOW=$(tput setaf 3)
    fi
fi

# --- 3. UI COMPONENTS ---
ui_clear() { printf "\033[H\033[J"; }

get_box_chars() {
    case $UI_STYLE in
        "double")  TL="╔"; TR="╗"; BL="╚"; BR="╝"; H="═"; V="║" ;;
        "heavy")   TL="┏"; TR="┓"; BL="┗"; BR="┛"; H="━"; V="┃" ;;
        "ascii")   TL="+"; TR="+"; BL="+"; BR="+"; H="-"; V="|" ;;
        "single")  TL="┌"; TR="┐"; BL="└"; BR="┘"; H="─"; V="│" ;;
        *)         TL="╭"; TR="╮"; BL="╰"; BR="╯"; H="─"; V="│" ;;
    esac
}

ui_header() {
    local title="$1"; local info="$2"
    get_box_chars
    ui_clear
    
    local width=60
    local t_len=${#title}
    local i_len=${#info}
    local space=$((width - t_len - i_len - 4))
    
    local filler=""; for ((i=0; i<space; i++)); do filler+=" "; done
    local line=""; for ((i=0; i<width; i++)); do line+="$H"; done

    printf "${C_BORDER}%s%s%s${RESET}\n" "$TL" "$line" "$TR"
    printf "${C_BORDER}%s${RESET} ${BOLD}${C_TITLE}%s${RESET}${filler}${C_MUTED}%s${RESET} ${C_BORDER}%s${RESET}\n" "$V" "$title" "$info" "$V"
    printf "${C_BORDER}%s%s%s${RESET}\n" "$BL" "$line" "$BR"
    printf "\n"
}

ui_item() {
    local label="$1"; local info="$2"; local is_sel="$3"; local is_cur="$4"
    
    local width=55
    if [ ${#info} -gt 30 ]; then info="...${info: -27}"; fi
    
    local prefix="   "
    local c_lbl="${C_TEXT}"
    local c_inf="${C_MUTED}"
    
    if [ "$is_cur" = "true" ]; then
        label="${label} (Active)"
        c_lbl="${C_TITLE}${BOLD}"
    fi
    
    if [ "$is_sel" = "true" ]; then
        # Use the dynamic UI_PROMPT variable here
        prefix=" ${C_SEL}${UI_PROMPT} "
        c_lbl="${C_SEL}${BOLD}"
        c_inf="${C_SEL}"
    fi

    printf "${prefix}%-30b %s%s${RESET}\n" "${c_lbl}${label}${RESET}" "${c_inf}" "$info"
}

ui_input() {
    local prompt="$1"
    tput cnorm
    printf "\n ${C_TITLE}➜${RESET} %s " "$prompt"
    read -r VAL
    tput civis
}

# --- 4. UTILS ---
parse_line() { local line="$1"; P1="${line%%|*}"; local r="${line#*|}"; P2="${r%%|*}"; P3="${r#*|}"; }

git_smart_pull() {
    printf "\n${C_MUTED}Checking remote...${RESET} "
    if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then printf "${C_YELLOW}⚠ No upstream.${RESET}\n"; return 0; fi
    if ! git diff-index --quiet HEAD --; then printf "${C_RED}⚠ Dirty state.${RESET} ${C_MUTED}Skipping pull.${RESET}\n"; sleep 1; return 0; fi
    printf "${C_TITLE}Syncing...${RESET} "
    if out=$(git pull --rebase 2>&1); then printf "${C_GREEN}✔ Done.${RESET}\n"; [ -d ".git" ] && touch .git/index; else printf "\n${C_RED}✖ Error:${RESET}\n%s\n" "$out"; read -rsn1 -p "Press key..."; fi
}