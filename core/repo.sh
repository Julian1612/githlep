#!/bin/bash
# @Intent: Core Logic für den Repository Manager
# @Dependencies: adapters/fs, adapters/ui

repo_main() {
    local cmd="$1"
    local arg1="$2"

    # Config laden
    local DB_FILE="$HOME/.config/git-suite/repos.json"
    fs_ensure_dir "$(dirname "$DB_FILE")"

    # --- CLI MODE: Add Current ---
    if [ "$cmd" == "-a" ]; then
        local current_path="$(pwd)"
        local default_name="$(basename "$current_path")"
        
        ui_header "ADD REPO" "$current_path"
        ui_input "Name [$default_name]:"
        local name="${UI_VAL:-$default_name}"
        
        ui_input "Shortcut (opt):"
        local short="$UI_VAL"
        
        fs_db_add_repo "$DB_FILE" "$current_path" "$name" "$short"
        ui_status "Repository gespeichert." "success"
        exit 0
    fi

    # --- INTERACTIVE MODE ---
    local selection=0
    local view_start=0
    local max_items=10
    
    # Loop für UI
    while true; do
        # 1. Daten laden (via Adapter)
        mapfile -t REPOS < <(fs_db_list_repos "$DB_FILE" "")
        local total=${#REPOS[@]}

        # 2. UI Header
        ui_header "REPO MANAGER" "$total Projects"
        
        if [ $total -eq 0 ]; then
            printf "   ${C_WARN}Keine Repos gefunden.${C_RESET}\n"
            printf "   Drücke 'a' um diesen Ordner hinzuzufügen.\n"
        fi

        # 3. Liste rendern
        for (( i=0; i<max_items; i++ )); do
            local idx=$((view_start + i))
            if [ $idx -ge $total ]; then break; fi
            
            # Parse Line: Name|Path|Shortcut
            IFS='|' read -r r_name r_path r_short <<< "${REPOS[$idx]}"
            
            local is_sel="false"
            [ $idx -eq $selection ] && is_sel="true"
            
            local label="$r_name"
            [ -n "$r_short" ] && label="$r_name [${C_ACCENT}$r_short${C_RESET}]"
            
            ui_item "$label" "$r_path" "$is_sel" "false"
        done

        # 4. Controls
        printf "\n${C_MUTED}──────────────────────────────────────────${C_RESET}\n"
        printf "${C_MUTED} [Enter] Open  [a] Add Current  [d] Delete  [q] Quit${C_RESET}"
        
        # 5. Input Handling
        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 k2
            case "$k2" in
                '[A') ((selection--)); [ $selection -lt 0 ] && selection=$((total-1)) ;;
                '[B') ((selection++)); [ $selection -ge $total ] && selection=0 ;;
            esac
            # Scroll Logic
            if [ $selection -lt $view_start ]; then view_start=$selection; fi
            if [ $selection -ge $((view_start + max_items)) ]; then view_start=$((selection - max_items + 1)); fi
            
        elif [[ $key == "q" ]]; then
            exit 0
            
        elif [[ $key == "a" ]]; then
             # Add Current Path logic inline for speed
            local p="$(pwd)"
            fs_db_add_repo "$DB_FILE" "$p" "$(basename "$p")" ""
            ui_status "Added $p" "success"

        elif [[ $key == "d" && $total -gt 0 ]]; then
            IFS='|' read -r _ del_path _ <<< "${REPOS[$selection]}"
            fs_db_delete_repo "$DB_FILE" "$del_path"
            ui_status "Deleted." "warn"
            selection=0
            
        elif [[ $key == "" && $total -gt 0 ]]; then
            IFS='|' read -r _ target_path _ <<< "${REPOS[$selection]}"
            
            ui_status "Opening..." "success"
            
            # Check for VS Code
            if command -v code >/dev/null 2>&1; then
                code -r "$target_path"
                exit 0
            else
                # Fallback: Spawn shell in new dir
                cd "$target_path" || exit 1
                $SHELL
                exit 0
            fi
        fi
    done
}
