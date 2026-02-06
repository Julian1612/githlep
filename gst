#!/bin/bash
# ---------------------------------------------------------------------------------------
# GRC - GIT REVERT COMMIT
# ---------------------------------------------------------------------------------------

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "\n\033[1mNAME\033[0m\n    grc - Git Revert Commit Wizard\n"
    echo -e "\033[1mDESCRIPTION\033[0m\n    Browse last 50 commits and revert a specific one."
    echo -e "    - Uses 'git revert --no-edit' to create a safe inverse commit.\n"
    exit 0
fi

BOLD='\033[1m'; RESET='\033[0m'; GREEN='\033[32m'; RED='\033[31m'; WHITE='\033[37m'; GRAY='\033[90m'; CYAN='\033[36m'
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then echo -e "${RED}Error: Not a git repo.${RESET}"; exit 1; fi
mapfile -t COMMITS < <(git log --pretty=format:"%h|%s|%cr" -n 50)
TOTAL=${#COMMITS[@]}; if [ $TOTAL -eq 0 ]; then echo -e "${GRAY}No commits found.${RESET}"; exit 0; fi
MAX_VISIBLE=10; SELECTED=0; VIEW_START=0; tput civis; cleanup() { tput cnorm; }; trap cleanup EXIT

while true; do
    if [ $SELECTED -lt $VIEW_START ]; then VIEW_START=$SELECTED; elif [ $SELECTED -ge $((VIEW_START + MAX_VISIBLE)) ]; then VIEW_START=$((SELECTED - MAX_VISIBLE + 1)); fi
    TERM_WIDTH=$(tput cols); echo -ne "\r"; echo -e "${BOLD}${WHITE}SELECT COMMIT TO REVERT${RESET} ${GRAY}(Last 50)${RESET}\033[K"; echo -e "${GRAY}----------------------------------------${RESET}\033[K"
    for (( i=0; i<MAX_VISIBLE; i++ )); do
        IDX=$((VIEW_START + i)); echo -ne "\033[K"
        if [ $IDX -ge $TOTAL ]; then echo -e ""; else
            IFS='|' read -r h m d <<< "${COMMITS[$IDX]}"; MAX=$((TERM_WIDTH - 35)); if [ ${#m} -gt $MAX ]; then m="${m:0:$((MAX-3))}..."; fi
            if [ $IDX -eq $SELECTED ]; then echo -e "${GREEN}${BOLD}  > ${CYAN}${h}${GREEN} ${m} ${GRAY}(${d})${RESET}"; else echo -e "    ${CYAN}${h}${RESET} ${m} ${GRAY}(${d})${RESET}"; fi
        fi
    done
    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then read -rsn2 k2; case "$k2" in '[A') ((SELECTED--)); [ $SELECTED -lt 0 ] && SELECTED=$((TOTAL - 1));; '[B') ((SELECTED++)); [ $SELECTED -ge $TOTAL ] && SELECTED=0;; esac; elif [[ $key == "q" ]]; then LINES_TO_CLEAR=$((2 + MAX_VISIBLE)); tput cuu $LINES_TO_CLEAR; tput ed; exit 0; elif [[ $key == "" ]]; then break; fi
    LINES_TO_CLEAR=$((2 + MAX_VISIBLE)); tput cuu $LINES_TO_CLEAR
done
LINES_TO_CLEAR=$((2 + MAX_VISIBLE)); tput cuu $LINES_TO_CLEAR; tput ed; tput cnorm
IFS='|' read -r h m d <<< "${COMMITS[$SELECTED]}"
echo -ne "${BOLD}${RED}Revert '${WHITE}$m${RED}' ($h)? [y/N]${RESET} "; read -rsn1 confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then echo -ne "\r\033[K"; echo -e "${GRAY}Reverting...${RESET}"; OUT=$(git revert --no-edit "$h" 2>&1); tput cuu 1; echo -ne "\r\033[K"
    if [ $? -eq 0 ]; then echo -e "${GREEN}✔ Reverted ${BOLD}$h${RESET}"; if [ -d ".git" ]; then touch .git/HEAD; fi; else echo -e "${RED}✖ Failed:${RESET}"; echo "$OUT"; fi
else echo -ne "\r\033[K"; fi
