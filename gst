#!/bin/bash
# ---------------------------------------------------------------------------------------
# GST - GIT STASH TOOL
# ---------------------------------------------------------------------------------------

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo -e "\n\033[1mNAME\033[0m\n    gst - Git Stash Manager\n"
    echo -e "\033[1mDESCRIPTION\033[0m\n    Manage git stashes visually."
    echo -e "    - List current stashes."
    echo -e "    - Create (+) new stash with message."
    echo -e "    - Select index (0, 1...) to Apply or Drop.\n"
    exit 0
fi

BOLD='\033[1m'; RESET='\033[0m'; GREEN='\033[32m'; CYAN='\033[36m'; RED='\033[31m'; GRAY='\033[90m'; WHITE='\033[37m'
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then echo -e "${RED}Error: Not a git repo.${RESET}"; exit 1; fi

while true; do
    mapfile -t STASHES < <(git stash list --format="%gd|%s|%cr"); TOTAL=${#STASHES[@]}
    echo -e "${BOLD}${WHITE}STASH MANAGER${RESET} ${GRAY}(${TOTAL} stashes)${RESET}"; echo -e "${GRAY}----------------------------------------${RESET}"
    echo -e "${GREEN}${BOLD}  + Create new stash${RESET}"
    for (( i=0; i<TOTAL; i++ )); do IFS='|' read -r r m d <<< "${STASHES[$i]}"; MAX=50; if [ ${#m} -gt $MAX ]; then m="${m:0:$MAX}..."; fi; echo -e "    ${CYAN}${r}${RESET} ${m} ${GRAY}(${d})${RESET}"; done
    echo -e "${GRAY}----------------------------------------${RESET}"; echo -e "${GRAY}Index (0..) to Apply/Drop, '+' to Create, 'q' to Quit${RESET}"
    echo -ne "${BOLD}${CYAN}Action:${RESET} "; read -r action
    if [[ "$action" == "q" ]]; then break; fi
    if [[ "$action" == "+" ]]; then echo -ne "Message: "; read -r msg; git stash push -m "$msg"; echo -e "${GREEN}✔ Stashed.${RESET}"; sleep 1; clear; continue; fi
    if [[ "$action" =~ ^[0-9]+$ ]] && [ "$action" -lt "$TOTAL" ]; then
        T="stash@{$action}"; echo -e "\nSelected: ${BOLD}$T${RESET}"; echo -e "1) Apply"; echo -e "2) Drop"; echo -ne "Choose: "; read -r sub
        case $sub in 1) git stash apply "$T"; echo -e "${GREEN}✔ Applied.${RESET}"; break ;; 2) git stash drop "$T"; echo -e "${RED}✔ Dropped.${RESET}"; sleep 1; clear ;; *) echo "Cancel."; sleep 1; clear ;; esac
    else clear; fi
done
