#!/bin/bash
set -e

# --- COLORS ---
BOLD='\033[1m'; RESET='\033[0m'; GREEN='\033[32m'; BLUE='\033[34m'; RED='\033[31m'; GRAY='\033[90m'

echo -e "${BOLD}${BLUE}🚀 STARTING GIT SUITE INSTALLATION...${RESET}"

# --- 1. PRE-CHECKS ---
echo -ne "Checking dependencies... "
if ! command -v git &> /dev/null; then echo -e "${RED}Error: git is not installed.${RESET}"; exit 1; fi
if ! command -v python3 &> /dev/null; then echo -e "${RED}Error: python3 is not installed.${RESET}"; exit 1; fi
echo -e "${GREEN}OK${RESET}"

# --- 2. CREATE DIRECTORIES ---
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config"
mkdir -p "$BIN_DIR"
mkdir -p "$CONFIG_DIR"
echo -e "${GREEN}✔ Directories created: ${GRAY}$BIN_DIR, $CONFIG_DIR${RESET}"

# --- 3. INSTALL TOOLS ---

# Function to write file
install_tool() {
    local name=$1
    local path="$BIN_DIR/$name"
    echo -ne "Installing $name... "
    cat > "$path"
    chmod +x "$path"
    echo -e "${GREEN}✔${RESET}"
}

# --- TOOL: GH (Dashboard) ---
install_tool "gh" << 'EOF'
#!/bin/bash
CONFIG_FILE="$HOME/.config/gh_favorites"
mkdir -p "$HOME/.config"
B='\033[1m'; R='\033[0m'; G='\033[32m'; C='\033[36m'; GR='\033[90m'; W='\033[37m'; M='\033[35m'; Y='\033[33m'; BL='\033[34m'; RED='\033[31m'

if [ ! -f "$CONFIG_FILE" ]; then
    cat <<EOC > "$CONFIG_FILE"
gs|Status (Short)|git status --short
gp|Smart Push & PR|~/.local/bin/gpp
gl|Pull (Update)|git pull --no-rebase
gm|Main & Pull|git switch main && git pull
glo|Log Graph|git log --oneline --graph
EOC
fi

show_help() {
    echo -e "${B}Usage:${R} gh [-l|-a|-d|-r]"
    exit 0
}

add_fav() { echo "$1|$2|$3" >> "$CONFIG_FILE"; echo -e "${G}✔ Added: $1${R}"; }
del_fav() { grep -v "^$1|" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"; echo -e "${Y}✔ Removed: $1${R}"; }

case "$1" in
    -a|--add) add_fav "$2" "$3" "$4"; exit 0 ;;
    -d|--del) del_fav "$2"; exit 0 ;;
    -r|--reset) rm "$CONFIG_FILE"; echo "Restored."; exit 0 ;;
    -l|--list) 
        clear; echo -e "${B}${BL}FULL REFERENCE${R}"
        fmt="  ${G}%-8s${R} | ${W}%-30s${R} | ${GR}%-40s${R}\n"
        echo -e "${B}${M}POWER TOOLS${R}"; echo -e "${GR}----------------------------------------${R}"
        printf "$fmt" "gac" "Smart Commit" "~/.local/bin/gac"
        printf "$fmt" "gsw" "Branch Switcher" "~/.local/bin/gsw"
        printf "$fmt" "rsw" "Repo Switcher" "~/.local/bin/rsw"
        printf "$fmt" "gpp" "Push & PR" "~/.local/bin/gpp"
        printf "$fmt" "gnr" "NPM Runner" "~/.local/bin/gnr"
        printf "$fmt" "gsy" "Sync/Rebase" "~/.local/bin/gsy"
        printf "$fmt" "gst" "Stash Manager" "~/.local/bin/gst"
        printf "$fmt" "gbd" "Delete Branch" "~/.local/bin/gbd"
        printf "$fmt" "grc" "Revert Commit" "~/.local/bin/grc"
        echo -e "\n${B}${C}CORE ALIASES${R}"; echo -e "${GR}----------------------------------------${R}"
        printf "$fmt" "gs" "Status" "git status -s"
        printf "$fmt" "ga" "Add File" "git add"
        printf "$fmt" "gaa" "Add All" "git add -A"
        printf "$fmt" "gc" "Commit" "git commit -m"
        printf "$fmt" "gl" "Pull" "git pull"
        printf "$fmt" "glo" "Log" "git log --graph"
        printf "$fmt" "gpr" "Open PR" "~/.local/bin/gpr"
        exit 0 ;;
    -h|--help) show_help ;;
esac

clear
echo -e "${B}${BL}GIT COMMAND CENTER${R}"; echo -e "${GR}Manage with 'gh -a', list all 'gh -l'${R}\n"
fmt="  ${G}%-8s${R} | ${W}%-30s${R} | ${GR}%-40s${R}\n"
echo -e "${B}${M}🚀 POWER TOOLS${R}"; echo -e "${GR}--------------------------------------------------------------------------------${R}"
printf "$fmt" "gac" "✨ Smart Commit" "~/.local/bin/gac"
printf "$fmt" "gsw" "🚀 Branch Switcher" "~/.local/bin/gsw"
printf "$fmt" "rsw" "📂 Repo Switcher" "~/.local/bin/rsw"
printf "$fmt" "gpp" "⬆️  Push & PR" "~/.local/bin/gpp"
printf "$fmt" "gnr" "⚡ NPM Runner" "~/.local/bin/gnr"
printf "$fmt" "gsy" "🔄 Sync/Rebase" "~/.local/bin/gsy"
printf "$fmt" "gst" "📦 Stash Manager" "~/.local/bin/gst"
printf "$fmt" "gbd" "🔥 Delete Branch" "~/.local/bin/gbd"
printf "$fmt" "grc" "↩️  Undo Commit" "~/.local/bin/grc"
echo -e "\n${B}${Y}⭐ FAVORITES${R}"; echo -e "${GR}--------------------------------------------------------------------------------${R}"
if [ -s "$CONFIG_FILE" ]; then
    while IFS='|' read -r cmd desc fullcmd; do [[ -n "$cmd" ]] && printf "$fmt" "$cmd" "$desc" "${fullcmd:-$cmd}"; done < "$CONFIG_FILE"
else echo -e "  ${GR}(No favorites. Add with gh -a)${R}"; fi
echo ""
EOF

# --- TOOL: GAC (Commit) ---
install_tool "gac" << 'EOF'
#!/bin/bash
if [[ "$1" == "-h" ]]; then echo "gac - Smart Commit Wizard"; exit 0; fi
B='\033[1m'; R='\033[0m'; G='\033[32m'; C='\033[36m'; GR='\033[90m'; RED='\033[31m'; W='\033[37m'
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then echo -e "${RED}Not a git repo.${R}"; exit 1; fi
git add -A; if git diff --cached --quiet; then echo -e "${GR}No changes.${R}"; exit 0; fi
OPT=("chore" "feat" "fix" "docs" "refactor"); DESC=("Maintenance" "Feature" "Bug fix" "Documentation" "Code change")
MAX=10; SEL=0; VS=0; TOT=${#OPT[@]}; tput civis; cleanup(){ tput cnorm; }; trap cleanup EXIT
while true; do
    if [ $SEL -lt $VS ]; then VS=$SEL; elif [ $SEL -ge $((VS+MAX)) ]; then VS=$((SEL-MAX+1)); fi
    echo -ne "\r"; echo -e "${B}${W}COMMIT TYPE${R}\033[K"; echo -e "${GR}----------------${R}\033[K"
    for (( i=0; i<MAX; i++ )); do IDX=$((VS+i)); echo -ne "\033[K"; if [ $IDX -ge $TOT ]; then echo ""; else if [ $IDX -eq $SEL ]; then echo -e "${G}${B}> ${OPT[$IDX]}${R} ${GR}(${DESC[$IDX]})${R}"; else echo -e "  ${OPT[$IDX]} ${GR}(${DESC[$IDX]})${R}"; fi; fi; done
    read -rsn1 k; if [[ $k == $'\x1b' ]]; then read -rsn2 k2; case "$k2" in '[A') ((SEL--));; '[B') ((SEL++));; esac; if [ $SEL -lt 0 ]; then SEL=$((TOT-1)); fi; if [ $SEL -ge $TOT ]; then SEL=0; fi; elif [[ $k == "" ]]; then break; elif [[ $k == "q" ]]; then exit 0; fi; tput cuu $((2+MAX))
done
tput cuu $((2+MAX)); tput ed; TYPE=${OPT[$SEL]}
echo -e "${G}✔ Type:${R} ${B}$TYPE${R}"
echo -ne "${B}${C}Scope${R} (opt): "; read s; tput cuu 1; echo -ne "\r\033[K"; [ -n "$s" ] && echo -e "${G}✔ Scope:${R} $s"
echo -ne "${B}${C}Message${R}: "; read m; tput cuu 1; echo -ne "\r\033[K"; [ -z "$m" ] && exit 1; echo -e "${G}✔ Msg:${R} $m"
FULL="$TYPE"; [ -n "$s" ] && FULL+="($s)"; FULL+=": $m"; echo -e "${GR}----------------${R}"; git commit -m "$FULL"
EOF

# --- TOOL: GSW (Switch) ---
install_tool "gsw" << 'EOF'
#!/bin/bash
if [[ "$1" == "-h" ]]; then echo "gsw - Branch Switcher"; exit 0; fi
B='\033[1m'; R='\033[0m'; G='\033[32m'; C='\033[36m'; GR='\033[90m'; M='\033[35m'
CUR=$(git branch --show-current); ALL=$(git branch --format='%(refname:short)'); BRS=()
for p in "main" "master"; do echo "$ALL" | grep -q "^$p$" && BRS+=("$p"); done
while read l; do [[ -n "$l" && "$l" != "main" && "$l" != "master" ]] && BRS+=("$l"); done <<< "$ALL"
TOT=${#BRS[@]}; MAX=10; SEL=0; VS=0; for i in "${!BRS[@]}"; do [[ "${BRS[$i]}" != "$CUR" ]] && SEL=$i && break; done
tput civis; cleanup(){ tput cnorm; }; trap cleanup EXIT
while true; do
    if [ $SEL -lt $VS ]; then VS=$SEL; elif [ $SEL -ge $((VS+MAX)) ]; then VS=$((SEL-MAX+1)); fi
    echo -ne "\r"; echo -e "${B}SWITCH BRANCH${R} ${GR}($TOT)${R}\033[K"; echo -e "${GR}Cur: ${C}$CUR${R}\033[K"; echo -e "${GR}----------------${R}\033[K"
    for (( i=0; i<MAX; i++ )); do IDX=$((VS+i)); echo -ne "\033[K"; if [ $IDX -ge $TOT ]; then echo ""; else 
        N=${BRS[$IDX]}; D=$N; [[ "$N" == "$CUR" ]] && D="${C}${B}$N${R} ${C}(Cur)${R}"; [[ "$N" =~ ^(main|master)$ ]] && D="${M}${B}$N${R}"
        if [ $IDX -eq $SEL ]; then echo -e "${G}${B}> $D${R}"; else echo -e "  $D${R}"; fi; fi; done
    read -rsn1 k; if [[ $k == $'\x1b' ]]; then read -rsn2 k2; case "$k2" in '[A') ((SEL--));; '[B') ((SEL++));; esac; [ $SEL -lt 0 ] && SEL=$((TOT-1)); [ $SEL -ge $TOT ] && SEL=0; elif [[ $k == "" ]]; then break; elif [[ $k == "q" ]]; then exit 0; fi; tput cuu $((3+MAX))
done
tput cuu $((3+MAX)); tput ed; T=${BRS[$SEL]}
git switch -q "$T" && echo -e "${G}✔ Switched to ${B}$T${R}" || exit 1
[ -d ".git" ] && touch .git/HEAD .git .; git update-index -q --refresh 2>/dev/null
echo -ne "${B}${C}Pull? [y/N]${R} "; read -rsn1 k; echo -ne "\r\033[K"; [[ "$k" =~ ^[Yy]$ ]] && git pull
EOF

# --- TOOL: RSW (Repo Switcher - FIXED) ---
install_tool "rsw" << 'EOF'
#!/bin/bash
CFG="$HOME/.config/repos.json"; B='\033[1m'; R='\033[0m'; G='\033[32m'; C='\033[36m'; GR='\033[90m'; RD='\033[31m'; W='\033[37m'; Y='\033[33m'; M='\033[35m'
if [[ "$1" == "-h" ]]; then echo -e "rsw - Repo Manager\nControls: Enter=Go, e=Edit, d=Del, a=Add, q=Quit"; exit 0; fi
[ ! -f "$CFG" ] && echo "[]" > "$CFG"

PY_L="import sys,json; s=sys.argv[2].lower(); 
try: d=json.load(open(sys.argv[1]))
except: d=[]
res=[]; ex=None
for r in d:
 n=r.get('name',''); p=r.get('path',''); sc=r.get('shortcut','')
 if not s or s in n.lower() or s in sc.lower(): res.append(f'{n}|{p}|{sc}'); 
 if s and sc.lower()==s: ex=f'{n}|{p}|{sc}'
print('JUMP|'+ex) if ex else [print(x) for x in res]"

PY_A="import sys,json; c,p,n,s=sys.argv[1:5]; d=json.load(open(c)); d.append({'name':n,'path':p,'shortcut':s}); json.dump(d,open(c,'w'),indent=2)"
PY_D="import sys,json; c,p=sys.argv[1:3]; d=[i for i in json.load(open(c)) if i['path']!=p]; json.dump(d,open(c,'w'),indent=2)"
PY_E="import sys,json; c,p,n,s=sys.argv[1:5]; d=json.load(open(c)); 
for i in d: 
 if i['path']==p: i['name']=n; i['shortcut']=s
json.dump(d,open(c,'w'),indent=2)"

if [[ "$1" == "-a" ]]; then echo -ne "${C}Name${R}: "; read n; echo -ne "${C}Label${R}: "; read s; python3 -c "$PY_A" "$CFG" "$PWD" "${n:-$(basename "$PWD")}" "$s"; echo "${G}✔ Added${R}"; exit 0; fi
S="$1"; [ -n "$S" ] && C=$(python3 -c "$PY_L" "$CFG" "$S") && [[ "$C" == JUMP* ]] && IFS='|' read _ n p s <<< "$C" && echo "${G}Jump: $n${R}" && code -r "$p" && exit 0
PWD=$(pwd -P); MAX=10; SEL=0; VS=0; tput civis; cleanup(){ tput cnorm; }; trap cleanup EXIT
while true; do
 mapfile -t R < <(python3 -c "$PY_L" "$CFG" "$S"); TOT=${#R[@]}
 [ $SEL -ge $TOT ] && SEL=$((TOT-1)); [ $SEL -lt 0 ] && SEL=0
 [ $SEL -lt $VS ] && VS=$SEL; [ $SEL -ge $((VS+MAX)) ] && VS=$((SEL-MAX+1))
 echo -ne "\r"; T="REPOS"; [ -n "$S" ] && T="FILTER: $S"; echo -e "${B}${W}$T${R} ${GR}($TOT)${R}\033[K"; echo -e "${GR}----------------${R}\033[K"
 for (( i=0; i<MAX; i++ )); do IDX=$((VS+i)); echo -ne "\033[K"; if [ $IDX -ge $TOT ]; then echo ""; else 
  IFS='|' read n p s <<< "${R[$IDX]}"; D=$n; [ -n "$s" ] && D+=" ${M}[$s]${R}"; [[ "$PWD" == "$p"* ]] && D="${C}${B}$n${R}${M}[$s]${R} ${C}(Cur)${R}"
  if [ $IDX -eq $SEL ]; then echo -e "${G}${B}> $D${R}"; else echo -e "  $D${R}"; fi; fi; done
 read -rsn1 k; if [[ $k == $'\x1b' ]]; then read -rsn2 k2; case "$k2" in '[A') ((SEL--));; '[B') ((SEL++));; esac; 
 elif [[ $k == "" && $TOT -gt 0 ]]; then IFS='|' read n p s <<< "${R[$SEL]}"; tput cnorm; echo -e "\n${G}✔ Open $n${R}"; code -r "$p"; exit 0
 elif [[ $k == "q" ]]; then break
 elif [[ $k == "a" ]]; then tput cnorm; echo -ne "\n\033[K${C}Add${R}: "; read n; echo -ne "${C}Label${R}: "; read s; python3 -c "$PY_A" "$CFG" "$PWD" "${n:-$(basename "$PWD")}" "$s"; S=""; tput civis
 elif [[ $k == "d" && $TOT -gt 0 ]]; then IFS='|' read n p s <<< "${R[$SEL]}"; tput cnorm; echo -ne "\n\033[K${RD}Del $n? [y/N]${R} "; read y; [[ "$y" =~ ^[Yy]$ ]] && python3 -c "$PY_D" "$CFG" "$p"; tput civis
 elif [[ $k == "e" && $TOT -gt 0 ]]; then IFS='|' read n p s <<< "${R[$SEL]}"; tput cnorm; echo -ne "\n\033[K${C}Name [$n]${R}: "; read nn; echo -ne "${C}Label [$s]${R}: "; read ns; python3 -c "$PY_E" "$CFG" "$p" "${nn:-$n}" "${ns:-$s}"; tput civis
 fi
 if [[ $k =~ [ade] ]]; then clear; else tput cuu $((2+MAX)); tput ed; fi
done; tput cnorm; clear
EOF

# --- TOOL: GPP (Push & PR) ---
install_tool "gpp" << 'EOF'
#!/bin/bash
if [[ "$1" == "-h" ]]; then echo "gpp - Push & PR"; exit 0; fi
B='\033[1m'; R='\033[0m'; G='\033[32m'; C='\033[36m'; RD='\033[31m'; GR='\033[90m'; Y='\033[33m'
! git rev-parse --is-inside-work-tree >/dev/null 2>&1 && exit 1
CB=$(git branch --show-current); echo -e "${B}PUSH & PR${R} (${GR}$CB${R})"
echo -ne "Pushing... "; OUT=$(git push "$@" 2>&1); ST=$?
if [ $ST -eq 0 ]; then echo -e "${G}✔${R}"; else
 if [[ "$OUT" == *"upstream"* ]]; then echo -e "${Y}⚠ No upstream${R}"; echo -ne "${C}Set upstream? [Y/n]${R} "; read -rsn1 k; echo ""; [[ "$k" =~ ^[Yy]?$ ]] && git push -u origin "$CB" && echo -e "${G}✔${R}" || exit 1
 else echo -e "${RD}✖ Failed${R}"; echo "$OUT"; exit 1; fi
fi
U=$(git config remote.origin.url); [ -z "$U" ] && exit 0
[[ "$U" == git@* ]] && U=${U//:/\/} && U=${U//git@/https:\/\/}; U=${U%.git}
[[ "$U" == *github* ]] && L="$U/compare/$CB?expand=1"
[[ "$U" == *gitlab* ]] && L="$U/-/merge_requests/new?merge_request[source_branch]=$CB"
[[ "$U" == *bitbucket* ]] && L="$U/pull-requests/new?source=$CB"
[[ "$U" == *azure* ]] && L="$U/pullrequestcreate?sourceRef=$CB"
echo -e "${GR}----------------${R}"; echo -ne "${G}${B}Open PR? [Y/n]${R} "; read -rsn1 k; echo ""
if [[ "$k" =~ ^[Yy]?$ ]]; then (wslview "$L" || xdg-open "$L" || open "$L") 2>/dev/null; fi
EOF

# --- TOOL: GBD (Delete) ---
install_tool "gbd" << 'EOF'
#!/bin/bash
B='\033[1m'; R='\033[0m'; RD='\033[31m'; GR='\033[90m'; W='\033[37m'; C='\033[36m'
CUR=$(git branch --show-current); BRS=(); while read l; do [[ -n "$l" ]] && BRS+=("$l"); done < <(git branch --format='%(refname:short)' | grep -vE "^($CUR|main|master)$")
TOT=${#BRS[@]}; [ $TOT -eq 0 ] && echo "No deletable branches." && exit 0
MAX=10; SEL=0; VS=0; tput civis; cleanup(){ tput cnorm; }; trap cleanup EXIT
while true; do
 if [ $SEL -lt $VS ]; then VS=$SEL; elif [ $SEL -ge $((VS+MAX)) ]; then VS=$((SEL-MAX+1)); fi
 echo -ne "\r"; echo -e "${B}${W}DELETE BRANCH${R} ${GR}($TOT)${R}\033[K"; echo -e "${GR}Cur: ${C}$CUR${R}\033[K"; echo -e "${GR}----------------${R}\033[K"
 for (( i=0; i<MAX; i++ )); do IDX=$((VS+i)); echo -ne "\033[K"; if [ $IDX -ge $TOT ]; then echo ""; else 
  if [ $IDX -eq $SEL ]; then echo -e "${RD}${B}> ${BRS[$IDX]}${R}"; else echo -e "  ${BRS[$IDX]}${R}"; fi; fi; done
 read -rsn1 k; if [[ $k == $'\x1b' ]]; then read -rsn2 k2; case "$k2" in '[A') ((SEL--));; '[B') ((SEL++));; esac; [ $SEL -lt 0 ] && SEL=$((TOT-1)); [ $SEL -ge $TOT ] && SEL=0; elif [[ $k == "" ]]; then break; elif [[ $k == "q" ]]; then exit 0; fi; tput cuu $((3+MAX))
done
tput cuu $((3+MAX)); tput ed; T=${BRS[$SEL]}
echo -ne "${RD}${B}Delete '$T'? [y/N]${R} "; read -rsn1 k; echo -ne "\r\033[K"; [[ "$k" =~ ^[Yy]$ ]] && git branch -D "$T" && echo -e "${G}✔ Deleted${R}"
EOF

# --- TOOL: GRC (Revert) ---
install_tool "grc" << 'EOF'
#!/bin/bash
B='\033[1m'; R='\033[0m'; G='\033[32m'; C='\033[36m'; GR='\033[90m'; W='\033[37m'; RD='\033[31m'
mapfile -t C < <(git log --pretty=format:"%h|%s|%cr" -n 50); TOT=${#C[@]}
[ $TOT -eq 0 ] && echo "No commits." && exit 0
MAX=10; SEL=0; VS=0; tput civis; cleanup(){ tput cnorm; }; trap cleanup EXIT
while true; do
 if [ $SEL -lt $VS ]; then VS=$SEL; elif [ $SEL -ge $((VS+MAX)) ]; then VS=$((SEL-MAX+1)); fi
 echo -ne "\r"; echo -e "${B}REVERT COMMIT${R}\033[K"; echo -e "${GR}----------------${R}\033[K"
 for (( i=0; i<MAX; i++ )); do IDX=$((VS+i)); echo -ne "\033[K"; if [ $IDX -ge $TOT ]; then echo ""; else IFS='|' read h m d <<< "${C[$IDX]}"; m="${m:0:50}"; 
  if [ $IDX -eq $SEL ]; then echo -e "${G}${B}> ${C}$h${G} $m ${GR}($d)${R}"; else echo -e "  ${C}$h${R} $m ${GR}($d)${R}"; fi; fi; done
 read -rsn1 k; if [[ $k == $'\x1b' ]]; then read -rsn2 k2; case "$k2" in '[A') ((SEL--));; '[B') ((SEL++));; esac; [ $SEL -lt 0 ] && SEL=$((TOT-1)); [ $SEL -ge $TOT ] && SEL=0; elif [[ $k == "" ]]; then break; elif [[ $k == "q" ]]; then exit 0; fi; tput cuu $((2+MAX))
done
tput cuu $((2+MAX)); tput ed; IFS='|' read h m d <<< "${C[$SEL]}"
echo -ne "${RD}${B}Revert '$m'? [y/N]${R} "; read -rsn1 k; echo -ne "\r\033[K"; [[ "$k" =~ ^[Yy]$ ]] && git revert --no-edit "$h" && echo -e "${G}✔ Reverted${R}"
EOF

# --- TOOL: GST (Stash) ---
install_tool "gst" << 'EOF'
#!/bin/bash
B='\033[1m'; R='\033[0m'; G='\033[32m'; C='\033[36m'; GR='\033[90m'; W='\033[37m'; RD='\033[31m'
while true; do
 mapfile -t S < <(git stash list --format="%gd|%s|%cr"); TOT=${#S[@]}
 echo -e "${B}STASH MANAGER${R} ($TOT)"; echo -e "${G}+ New${R}"
 for (( i=0; i<TOT; i++ )); do IFS='|' read r m d <<< "${S[$i]}"; echo -e " ${C}$i${R}: $m ${GR}($d)${R}"; done
 echo -e "${GR}----------------${R}"; echo -ne "${C}Opt (0..$((TOT-1)), +, q)${R}: "; read a; [ "$a" == "q" ] && break
 if [ "$a" == "+" ]; then echo -ne "Msg: "; read m; git stash push -m "$m"; clear; continue; fi
 if [[ "$a" =~ ^[0-9]+$ ]] && [ "$a" -lt $TOT ]; then
  echo -e "\n1) Apply  2) Drop"; read s; T="stash@{$a}"
  case $s in 1) git stash apply "$T";; 2) git stash drop "$T";; esac; sleep 1; clear
 else clear; fi
done
EOF

# --- TOOL: GNR (NPM) ---
install_tool "gnr" << 'EOF'
#!/bin/bash
[ ! -f "package.json" ] && echo "No package.json" && exit 1
B='\033[1m'; R='\033[0m'; G='\033[32m'; C='\033[36m'; GR='\033[90m'
mapfile -t S < <(python3 -c "import json; [print(f'{k}|{v}') for k,v in json.load(open('package.json')).get('scripts',{}).items()]")
TOT=${#S[@]}; MAX=10; SEL=0; VS=0; tput civis; cleanup(){ tput cnorm; }; trap cleanup EXIT
while true; do
 if [ $SEL -lt $VS ]; then VS=$SEL; elif [ $SEL -ge $((VS+MAX)) ]; then VS=$((SEL-MAX+1)); fi
 echo -ne "\r"; echo -e "${B}NPM SCRIPTS${R} ($TOT)\033[K"; echo -e "${GR}----------------${R}\033[K"
 for (( i=0; i<MAX; i++ )); do IDX=$((VS+i)); echo -ne "\033[K"; if [ $IDX -ge $TOT ]; then echo ""; else IFS='|' read n c <<< "${S[$IDX]}"; c="${c:0:40}"; 
  if [ $IDX -eq $SEL ]; then echo -e "${G}${B}> $n${R} ${GR}- $c${R}"; else echo -e "  ${C}$n${R} ${GR}- $c${R}"; fi; fi; done
 read -rsn1 k; if [[ $k == $'\x1b' ]]; then read -rsn2 k2; case "$k2" in '[A') ((SEL--));; '[B') ((SEL++));; esac; [ $SEL -lt 0 ] && SEL=$((TOT-1)); [ $SEL -ge $TOT ] && SEL=0; elif [[ $k == "" ]]; then break; elif [[ $k == "q" ]]; then exit 0; fi; tput cuu $((2+MAX))
done
tput cuu $((2+MAX)); tput ed; IFS='|' read n _ <<< "${S[$SEL]}"; echo -e "${G}Running: $n${R}"; npm run "$n"
EOF

# --- TOOL: GSY (Sync) ---
install_tool "gsy" << 'EOF'
#!/bin/bash
B='\033[1m'; R='\033[0m'; G='\033[32m'; GR='\033[90m'
M="main"; git show-ref -q refs/remotes/origin/master && M="master"
echo -e "${B}SYNC${R} (Rebase on $M)"; echo -ne "Fetching... "; git fetch origin -q; echo -e "${G}✔${R}"
echo -ne "Rebasing... "; OUT=$(git rebase "origin/$M" 2>&1); if [ $? -eq 0 ]; then echo -e "${G}✔ Done${R}"; else echo -e "\n${RD}Conflict${R}"; echo "$OUT"; fi
EOF

# --- TOOL: GPR (Open PR) ---
install_tool "gpr" << 'EOF'
#!/bin/bash
U=$(git config remote.origin.url); B=$(git branch --show-current)
[[ "$U" == git@* ]] && U=${U//:/\/} && U=${U//git@/https:\/\/}; U=${U%.git}
[[ "$U" == *github* ]] && L="$U/compare/$B?expand=1"
[[ "$U" == *gitlab* ]] && L="$U/-/merge_requests/new?merge_request[source_branch]=$B"
echo "Opening $L"; (wslview "$L" || xdg-open "$L" || open "$L") 2>/dev/null
EOF

# --- 4. CREATE ZSH FUNCTIONS ---
echo -ne "Creating function library... "
cat > "$HOME/.git_functions.zsh" << 'EOF'
# GIT PROFESSIONAL SUITE
unalias gs ga gaa gc gp gl glo gd gm gclean 2>/dev/null
_ph() { echo -e "\n\033[1;34mCMD:\033[0m \033[1;32m$1\033[0m\n\033[1;34mDESC:\033[0m $2\n\033[1;34mRUN:\033[0m \033[90m$3\033[0m\n"; }
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then export PATH="$HOME/.local/bin:$PATH"; fi

alias gh='~/.local/bin/gh'
alias gac='~/.local/bin/gac'; alias gsw='~/.local/bin/gsw'; alias rsw='~/.local/bin/rsw'
alias gbd='~/.local/bin/gbd'; alias grc='~/.local/bin/grc'; alias gst='~/.local/bin/gst'
alias gnr='~/.local/bin/gnr'; alias gsy='~/.local/bin/gsy'; alias gpr='~/.local/bin/gpr'
alias g='git'; alias gpu='git push -u origin $(git branch --show-current)'; alias gcn='git switch -c'

gs() { if [[ "$1" == "-h" ]]; then _ph "gs" "Status" "git status -s"; else git status --short "$@"; fi }
ga() { if [[ "$1" == "-h" ]]; then _ph "ga" "Add" "git add"; else git add "$@"; fi }
gaa() { if [[ "$1" == "-h" ]]; then _ph "gaa" "Add All" "git add -A"; else git add -A "$@"; fi }
gc() { if [[ "$1" == "-h" ]]; then _ph "gc" "Commit" "git commit -m"; else git commit -m "$@"; fi }
gp() { if [[ "$1" == "-h" ]]; then _ph "gp" "Push & PR" "~/.local/bin/gpp"; else ~/.local/bin/gpp "$@"; fi }
gl() { if [[ "$1" == "-h" ]]; then _ph "gl" "Pull" "git pull"; else git pull --no-rebase "$@"; fi }
glo() { if [[ "$1" == "-h" ]]; then _ph "glo" "Log" "git log"; else git log --oneline --graph --decorate "$@"; fi }
gd() { if [[ "$1" == "-h" ]]; then _ph "gd" "Diff" "git diff"; else git diff "$@"; fi }
gm() { if [[ "$1" == "-h" ]]; then _ph "gm" "Main & Pull" "switch main && pull"; else git switch main && git pull; fi }
EOF
echo -e "${GREEN}✔${RESET}"

# --- 5. UPDATE SHELL CONFIG ---
RC_FILE="$HOME/.zshrc"
[ ! -f "$RC_FILE" ] && RC_FILE="$HOME/.bashrc"
echo -ne "Updating $RC_FILE... "

if ! grep -q "source.*\.git_functions.zsh" "$RC_FILE"; then
    echo -e "\n# GIT PRO SUITE\n[ -f ~/.git_functions.zsh ] && source ~/.git_functions.zsh" >> "$RC_FILE"
    echo -e "${GREEN}✔ Added source command${RESET}"
else
    echo -e "${BLUE}✔ Already configured${RESET}"
fi

echo -e "\n${BOLD}${GREEN}✅ INSTALLATION COMPLETE!${RESET}"
echo -e "Please restart your terminal or run: ${BOLD}source $RC_FILE${RESET}"
