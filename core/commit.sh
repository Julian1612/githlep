#!/bin/bash
# @Intent: Core Logic für den Smart Commit Wizard (Conventional Commits)
# @Dependencies: adapters/git, adapters/ui

commit_main() {
    # 1. Repo Check
    if ! git_check_is_repo; then
        ui_status "Kein Git-Repository." "error"
        exit 1
    fi

    # 2. Status Review
    ui_header "COMMIT WIZARD" "Reviewing Changes"
    local status_output=$(git_get_short_status)
    
    if [ -z "$status_output" ]; then
        ui_status "Keine Änderungen zum Committen." "info"
        exit 0
    fi
    
    printf "${C_MUTED}%s${C_RESET}\n" "$status_output"
    ui_input "Alle Änderungen stagen? [Y/n]"
    [[ "$UI_VAL" =~ ^[Nn]$ ]] || git add -A

    # 3. Commit Type Selection
    local types=("feat" "fix" "chore" "docs" "refactor" "style" "test")
    local descs=("New Feature" "Bug Fix" "Maintenance" "Documentation" "Refactoring" "Styling" "Testing")
    local sel=0
    
    while true; do
        ui_header "COMMIT TYPE" "Select Type"
        for i in "${!types[@]}"; do
            local is_sel="false"
            [ $i -eq $sel ] && is_sel="true"
            ui_item "${types[$i]}" "${descs[$i]}" "$is_sel" "false"
        done
        
        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 k2
            case "$k2" in
                '[A') ((sel--)); [ $sel -lt 0 ] && sel=$((${#types[@]}-1)) ;;
                '[B') ((sel++)); [ $sel -ge ${#types[@]} ] && sel=0 ;;
            esac
        elif [[ $key == "" ]]; then
            break
        elif [[ $key == "q" ]]; then
            exit 0
        fi
    done
    
    local final_type="${types[$sel]}"

    # 4. Scope & Message
    ui_header "COMMIT MESSAGE" "$final_type"
    ui_input "Scope (optional, z.B. ui, core):"
    local scope="$UI_VAL"
    
    ui_input "Nachricht (kurz & präzise):"
    local msg="$UI_VAL"
    
    if [ -z "$msg" ]; then
        ui_status "Nachricht darf nicht leer sein!" "error"
        exit 1
    fi

    # 5. Build & Execute
    local full_msg="$final_type"
    [ -n "$scope" ] && full_msg+="($scope)"
    full_msg+=": $msg"
    
    ui_header "FINALIZE" "Commit & Push"
    printf " Message: ${C_MAIN}%s${C_RESET}\n\n" "$full_msg"
    
    if git commit -m "$full_msg"; then
        ui_status "Commit erfolgreich." "success"
        ui_input "Direkt pushen? [y/N]"
        if [[ "$UI_VAL" =~ ^[Yy]$ ]]; then
            ui_status "Pushing..." "info"
            git push && ui_status "Push abgeschlossen." "success"
        fi
    else
        ui_status "Commit fehlgeschlagen." "error"
    fi
}
