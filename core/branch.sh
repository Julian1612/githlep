#!/bin/bash
# @Intent: Core Logic für Branch Management (Switch, Create, Delete, Rename)
# @Dependencies: adapters/git, adapters/ui

branch_main() {
    # 1. Pre-Check: Sind wir in einem Repo?
    if ! git_check_is_repo; then
        ui_status "Kein Git-Repository." "error"
        exit 1
    fi

    # Config
    local MAX_ITEMS=10
    local selection=0
    local view_start=0
    
    # State Loop
    while true; do
        # 1. Daten laden (via Adapter)
        local current=$(git_get_current_branch)
        mapfile -t ALL_BRANCHES < <(git_get_branches)
        
        # 2. Sortieren & Filtern (Priority Sorting)
        # Wir bauen eine neue Liste: Prio-Branches zuerst, dann der Rest
        local BRANCHES=()
        local PRIO=("main" "master" "dev" "development" "staging")
        
        # A) Add Priority Branches (if they exist)
        for p in "${PRIO[@]}"; do
            # Check if p is in ALL_BRANCHES
            for b in "${ALL_BRANCHES[@]}"; do
                if [[ "$b" == "$p" && "$b" != "$current" ]]; then
                    BRANCHES+=("$b")
                    break
                fi
            done
        done
        
        # B) Add Rest (excluding current and already added)
        for b in "${ALL_BRANCHES[@]}"; do
            if [[ "$b" == "$current" ]]; then continue; fi
            # Skip if already in BRANCHES
            local exists="false"
            for added in "${BRANCHES[@]}"; do [[ "$added" == "$b" ]] && exists="true"; done
            if [ "$exists" == "false" ]; then BRANCHES+=("$b"); fi
        done
        
        local total=${#BRANCHES[@]}
        
        # Bounds Check (Falls nach Löschen selection out of bounds)
        if [ $selection -ge $total ] && [ $total -gt 0 ]; then selection=$((total - 1)); fi
        if [ $selection -lt 0 ]; then selection=0; fi

        # 3. UI Header
        ui_header "BRANCH MANAGER" "Aktuell: $current"
        
        if [ $total -eq 0 ]; then
            printf "   ${C_MUTED}(Keine anderen Branches)${C_RESET}\n"
        fi

        # 4. Liste rendern
        for (( i=0; i<MAX_ITEMS; i++ )); do
            local idx=$((view_start + i))
            if [ $idx -ge $total ]; then break; fi
            
            local b_name="${BRANCHES[$idx]}"
            local is_sel="false"
            [ $idx -eq $selection ] && is_sel="true"
            
            # Icon Logic
            local label="$b_name"
            if [[ "$b_name" =~ ^(main|master)$ ]]; then
                label="${SYM_LIGHTNING} $b_name"
            fi
            
            ui_item "$label" "" "$is_sel" "false"
        done

        # 5. Footer Controls
        printf "\n${C_MUTED}──────────────────────────────────────────${C_RESET}\n"
        printf "${C_MUTED} [Enter] Switch  [n] New  [d] Delete  [r] Rename  [q] Quit${C_RESET}"
        
        # 6. Input Handling
        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 k2
            case "$k2" in
                '[A') ((selection--)); [ $selection -lt 0 ] && selection=$((total-1)) ;;
                '[B') ((selection++)); [ $selection -ge $total ] && selection=0 ;;
            esac
            # Scroll Logic
            if [ $selection -lt $view_start ]; then view_start=$selection; fi
            if [ $selection -ge $((view_start + MAX_ITEMS)) ]; then view_start=$((selection - MAX_ITEMS + 1)); fi
            
        elif [[ $key == "q" ]]; then
            exit 0
            
        elif [[ $key == "" ]]; then
            # SWITCH
            [ $total -eq 0 ] && continue
            local target="${BRANCHES[$selection]}"
            ui_status "Wechsle zu $target..." "success"
            git_switch_branch "$target"
            exit 0
            
        elif [[ $key == "n" ]]; then
            # NEW
            ui_input "Neuer Branch Name:"
            local name="$UI_VAL"
            if [ -n "$name" ]; then
                git_create_branch "$name" && exit 0
            fi
            
        elif [[ $key == "d" ]]; then
            # DELETE
            [ $total -eq 0 ] && continue
            local target="${BRANCHES[$selection]}"
            
            # Protection
            if [[ "$target" =~ ^(main|master)$ ]]; then
                ui_status "Master/Main darf nicht gelöscht werden!" "error"
                continue
            fi
            
            ui_input "Lösche '$target'? [y/N]"
            if [[ "$UI_VAL" =~ ^[Yy]$ ]]; then
                git_delete_branch "$target"
                ui_status "Gelöscht." "warn"
                selection=0 # Reset Selection to avoid ghost pointer
            fi
            
        elif [[ $key == "r" ]]; then
            # RENAME
            [ $total -eq 0 ] && continue
            local target="${BRANCHES[$selection]}"
            ui_input "Neuer Name für '$target':"
            local new_name="$UI_VAL"
            if [ -n "$new_name" ]; then
                git_rename_branch "$target" "$new_name"
                ui_status "Umbenannt." "success"
            fi
        fi
    done
}
