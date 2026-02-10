#!/bin/bash
# GIT SUITE CORE v11

# --- CONFIG ---
CONFIG_DIR="$HOME/.config/git-suite"
SETTINGS_CONF="$CONFIG_DIR/settings.conf"
THEME_CONF="$CONFIG_DIR/theme.conf"
mkdir -p "$CONFIG_DIR"

if [ -f "$SETTINGS_CONF" ]; then source "$SETTINGS_CONF"; fi

# Defaults
: "${C_BORDER_IDX:=4}"
: "${C_TITLE_IDX:=6}"
: "${C_SEL_IDX:=2}"
: "${C_TEXT_IDX:=7}"
: "${C_MUTED_IDX:=8}"
: "${UI_STYLE:=rounded}"
: "${UI_PROMPT:=❯}"

if [ -z "$PREVIEW_MODE" ] && [ -f "$THEME_CONF" ]; then source "$THEME_CONF"; fi

# --- COLORS ---
if [ -t 1 ]; then
    COLORS=$(tput colors 2>/dev/null || echo 8)
    if [ "$COLORS" -ge 8 ]; then
        BOLD=$(tput bold); RESET=$(tput sgr0)
        C_BORDER=$(tput setaf "$C_BORDER_IDX")
        C_TITLE=$(tput setaf "$C_TITLE_IDX")
        C_SEL=$(tput setaf "$C_SEL_IDX")
        C_TEXT=$(tput setaf "$C_TEXT_IDX")
        [ "$COLORS" -ge 256 ] && C_MUTED=$(tput setaf 240) || C_MUTED=$(tput setaf 0)
        C_RED=$(tput setaf 1); C_GREEN=$(tput setaf 2); C_YELLOW=$(tput setaf 3); C_BLUE=$(tput setaf 4)
        C_SUCCESS="$C_GREEN"; C_DANGER="$C_RED"; C_WARN="$C_YELLOW"; C_ACCENT="$C_TITLE"
    else
        BOLD=""; RESET=""; C_BORDER=""; C_TITLE=""; C_SEL=""; C_TEXT=""; C_MUTED=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
    fi
fi

# --- UI ---
ui_clear() { printf "\033[H\033[J"; }
cursor_off() { tput civis 2>/dev/null; }
cursor_on()  { tput cnorm 2>/dev/null; }

get_box_chars() {
    case $UI_STYLE in
        "double")  TL="╔"; TR="╗"; BL="╚"; BR="╝"; H="═"; V="║" ;;
        "heavy")   TL="┏"; TR="┓"; BL="┗"; BR="┛"; H="━"; V="┃" ;;
        "ascii")   TL="+"; TR="+"; BL="+"; BR="+"; H="-"; V="|" ;;
        *)         TL="╭"; TR="╮"; BL="╰"; BR="╯"; H="─"; V="│" ;;
    esac
}

ui_header() {
    local title="$1"; local info="$2"
    get_box_chars
    ui_clear
    local width=60
    local t_len=${#title}; local i_len=${#info}
    local space=$((width - t_len - i_len - 4))
    [ $space -lt 0 ] && space=0
    local filler=""; for ((i=0; i<space; i++)); do filler+=" "; done
    local line=""; for ((i=0; i<width; i++)); do line+="$H"; done
    printf "${C_BORDER}%s%s%s${RESET}\n" "$TL" "$line" "$TR"
    printf "${C_BORDER}%s${RESET} ${BOLD}${C_TITLE}%s${RESET}${filler}${C_MUTED}%s${RESET} ${C_BORDER}%s${RESET}\n" "$V" "$title" "$info" "$V"
    printf "${C_BORDER}%s%s%s${RESET}\n" "$BL" "$line" "$BR"
    printf "\n"
}

ui_item() {
    local label="$1"; local info="$2"; local is_sel="$3"; local is_cur="$4"
    if [ ${#info} -gt 35 ]; then info="...${info: -32}"; fi
    local prefix="   "; local c_lbl="${C_TEXT}"; local c_inf="${C_MUTED}"
    if [ "$is_cur" = "true" ]; then label="${label} (Active)"; c_lbl="${C_TITLE}${BOLD}"; fi
    if [ "$is_sel" = "true" ]; then prefix=" ${C_SEL}${UI_PROMPT} "; c_lbl="${C_SEL}${BOLD}"; c_inf="${C_SEL}"; fi
    printf "${prefix}%-30b %s%s${RESET}\n" "${c_lbl}${label}${RESET}" "${c_inf}" "$info"
}

ui_input() {
    local prompt="$1"; local default="$2"
    cursor_on
    local p_str="${C_TITLE}➜${RESET} $prompt"
    [ -n "$default" ] && p_str="$p_str [${C_MUTED}$default${RESET}]"
    printf "\n %b: " "$p_str"
    read -r VAL
    VAL="${VAL:-$default}"
    cursor_off
}

ui_line() { printf "${C_MUTED}────────────────────────────────────────────────────────${RESET}\n"; }

parse_line() {
    local line="$1"
    P1="${line%%|*}"; local r="${line#*|}"; P2="${r%%|*}"; P3="${r#*|}"
    [[ "$P3" == "$P2" && "$line" != *"|"*|* ]] && P3=""
}

check_git() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "${C_RED}Error: Not a git repository.${RESET}"; exit 1
    fi
}
