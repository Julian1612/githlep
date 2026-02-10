#!/bin/bash
set -e

echo "🔧 Starte Reparatur der Git Suite..."

# 1. Ordner Struktur sicherstellen
mkdir -p lib src

# ---------------------------------------------------------
# DATEI 1: lib/git-suite-lib.sh (Die Bibliothek)
# ---------------------------------------------------------
cat << 'EOF' > lib/git-suite-lib.sh
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
EOF
chmod +x lib/git-suite-lib.sh
echo "✅ lib/git-suite-lib.sh erstellt."

# ---------------------------------------------------------
# DATEI 2: gh (Das Dashboard)
# ---------------------------------------------------------
cat << 'EOF' > gh
#!/bin/bash
# GIT SUITE DASHBOARD v11

# 1. LIB FINDER
LIB_PATH="$HOME/.local/bin/git-suite-lib.sh"
[ ! -f "$LIB_PATH" ] && LIB_PATH="$(dirname "$0")/git-suite-lib.sh"
[ ! -f "$LIB_PATH" ] && LIB_PATH="$(dirname "$0")/lib/git-suite-lib.sh"

if [ -f "$LIB_PATH" ]; then source "$LIB_PATH"; else
    echo "Error: git-suite-lib.sh not found. Run installer.sh"; exit 1
fi

CONF="$HOME/.config/git-suite/aliases.conf"
mkdir -p "$(dirname "$CONF")"; touch "$CONF"

add_alias() {
    ui_header "ADD SHORTCUT" "New Favorite"
    ui_input "Kürzel" ""; local s="$VAL"; [ -z "$s" ] && return
    ui_input "Name" ""; local n="$VAL"
    ui_input "Befehl" ""; local c="$VAL"
    echo "$s|$n|$c" >> "$CONF"
}

edit_alias() {
    local line="$1"; parse_line "$line"
    ui_header "EDIT SHORTCUT" "$P1"
    ui_input "Kürzel" "$P1"; local s="$VAL"
    ui_input "Name" "$P2"; local n="$VAL"
    ui_input "Befehl" "$P3"; local c="$VAL"
    t=$(mktemp)
    while IFS= read -r l; do
        if [[ "$l" == "$line" ]]; then echo "$s|$n|$c" >> "$t"; else echo "$l" >> "$t"; fi
    done < "$CONF"; mv "$t" "$CONF"
}

delete_alias() {
    local line="$1"; parse_line "$line"
    cursor_on; printf "\n${C_DANGER}Lösche '$P1'? [y/N]${RESET} "; read -r y
    if [[ "$y" =~ ^[Yy]$ ]]; then
        t=$(mktemp); grep -Fv "$line" "$CONF" > "$t"; mv "$t" "$CONF"
    fi; cursor_off
}

SEL=0; VS=0; MAX=12
while true; do
    LINES=(); if [ -s "$CONF" ]; then
        while IFS= read -r l; do [[ -z "$l" ]] && continue; LINES+=("$l"); done < "$CONF"
    fi
    TOT=${#LINES[@]}
    [ $SEL -ge $TOT ] && SEL=$((TOT-1)); [ $SEL -lt 0 ] && SEL=0
    [ $SEL -lt $VS ] && VS=$SEL; [ $SEL -ge $((VS+MAX)) ] && VS=$((SEL-MAX+1))

    ui_header "CONTROL CENTER" "Git Suite"
    if [ $TOT -eq 0 ]; then
        echo "  ${C_MUTED}(Keine Favoriten)${RESET}"
        echo "  ${C_MUTED}Tipp: Führe installer.sh erneut aus für Defaults.${RESET}"
    else
        for (( i=0; i<MAX; i++ )); do
            IDX=$((VS+i)); [ $IDX -ge $TOT ] && break
            L="${LINES[$IDX]}"
            if [[ "$L" =~ ^# ]]; then
                CLEAN="${L/\# /}"; printf "  ${C_ACCENT}${BOLD}%s${RESET}\n" "$CLEAN"
            else
                parse_line "$L"; IS_SEL="false"; [ $IDX -eq $SEL ] && IS_SEL="true"
                ui_item "$P1" "$P2" "$IS_SEL" "false"
            fi
        done
    fi
    ui_line
    printf "${C_MUTED} [Enter] Run  [a] Add  [e] Edit  [d] Delete  [q] Quit${RESET}"
    
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 k2; case "$k2" in
            '[A') ((SEL--)); while [ $SEL -ge 0 ] && [[ "${LINES[$SEL]}" =~ ^# ]]; do ((SEL--)); done ;;
            '[B') ((SEL++)); while [ $SEL -lt $TOT ] && [[ "${LINES[$SEL]}" =~ ^# ]]; do ((SEL++)); done ;;
        esac
    elif [[ $key == "" ]]; then
        [ $TOT -eq 0 ] && continue; L="${LINES[$SEL]}"
        if [[ ! "$L" =~ ^# ]]; then
            parse_line "$L"; cursor_on
            printf "\n${C_SUCCESS}Running: $P2...${RESET}\n"
            eval "$P3"; exit 0
        fi
    elif [[ $key == "a" ]]; then add_alias
    elif [[ $key == "e" && $TOT -gt 0 ]]; then [[ ! "${LINES[$SEL]}" =~ ^# ]] && edit_alias "${LINES[$SEL]}"
    elif [[ $key == "d" && $TOT -gt 0 ]]; then [[ ! "${LINES[$SEL]}" =~ ^# ]] && delete_alias "${LINES[$SEL]}"
    elif [[ $key == "q" ]]; then exit 0
    fi
done
EOF
chmod +x gh
echo "✅ gh (Dashboard) erstellt."

# ---------------------------------------------------------
# DATEI 3: gpc (Project Creator)
# ---------------------------------------------------------
cat << 'EOF' > gpc
#!/bin/bash
source "$HOME/.local/bin/git-suite-lib.sh"

fetch_joke() {
    if command -v curl >/dev/null 2>&1; then
        JOKE=$(curl -s --max-time 1 "https://v2.jokeapi.dev/joke/programming?type=single&format=txt")
    fi
    [ -z "$JOKE" ] && JOKE="Hello World!"
    echo "$JOKE" | sed 's/"/\\"/g'
}

create_class() {
    local lang=""
    if [ -f "Makefile" ]; then
        grep -q "cpp" Makefile && lang="cpp"; grep -q "gcc" Makefile && lang="c"
    elif [ -f "requirements.txt" ]; then lang="python"; fi

    if [ -z "$lang" ]; then
        ui_header "NEW CLASS" "Select Language"
        echo " 1) C++"; echo " 2) C"; echo " 3) Python"; printf "Choice: "; read -r c
        case "$c" in 1) lang="cpp";; 2) lang="c";; 3) lang="python";; *) return;; esac
    fi
    ui_input "Class Name" "MyClass"; CLASS_NAME="$VAL"; [ -z "$CLASS_NAME" ] && return
    
    cursor_on
    if [ "$lang" == "cpp" ]; then
        mkdir -p src includes
        # CPP Headers/Source creation (simplified)
        echo "class $CLASS_NAME {};" > "includes/$CLASS_NAME.h"
        echo "#include \"../includes/$CLASS_NAME.h\"" > "src/$CLASS_NAME.cpp"
    elif [ "$lang" == "python" ]; then
        mkdir -p src; echo "class $CLASS_NAME: pass" > "src/$CLASS_NAME.py"
    fi
    printf "${C_SUCCESS}✔ Created class $CLASS_NAME${RESET}\n"; sleep 1; cursor_off
}

create_project() {
    ui_header "PROJECT WIZARD" "New Project"
    echo " 1) C++"; echo " 2) C"; echo " 3) Python"; printf "Choice: "; read -r c
    case "$c" in 1) L="cpp";; 2) L="c";; 3) L="python";; *) return;; esac
    ui_input "Name" "my-project"; PN="$VAL"; [ -d "$PN" ] && return
    
    mkdir -p "$PN"; cd "$PN" || exit
    git init -q; echo "# $PN" > README.md
    
    if [ "$L" == "cpp" ]; then
        mkdir -p src includes obj; echo "obj/" >> .gitignore
        JOKE=$(fetch_joke)
        echo -e "#include <iostream>\nint main(){ std::cout << \"$JOKE\" << std::endl; return 0; }" > src/main.cpp
        echo -e "all:\n\tg++ src/main.cpp -o $PN" > Makefile
    elif [ "$L" == "python" ]; then
        mkdir src; echo "print('Hello Python')" > src/main.py
    fi
    printf "${C_SUCCESS}✔ Project created!${RESET}\n"; exit 0
}

if [[ "$1" == "-c" ]]; then create_class; exit 0; fi
if [[ "$1" == "new" ]]; then create_project; exit 0; fi

while true; do
    ui_header "PROJECT CREATOR" "Menu"
    echo " 1) New Project"; echo " 2) New Class"; echo " q) Quit"
    read -rsn1 k
    case "$k" in 1) create_project;; 2) create_class;; q) exit 0;; esac
done
EOF
chmod +x gpc
echo "✅ gpc (Project Creator) erstellt."

# ---------------------------------------------------------
# DATEI 4: installer.sh (Der Installer)
# ---------------------------------------------------------
cat << 'EOF' > installer.sh
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
EOF
chmod +x installer.sh
echo "✅ installer.sh erstellt."

# ---------------------------------------------------------
# RUN INSTALLER
# ---------------------------------------------------------
./installer.sh