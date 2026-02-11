#!/bin/bash
# @Intent: Zentrales Dashboard zur Visualisierung der Suite-Module
# @Description: Zeigt Workflow-Tools, Aktionen und Favoriten an.
# @Dependencies: adapters/ui

dashboard_main() {
    ui_header "GIT PROFESSIONAL SUITE" "Liquid Core v3.0"

    # Helfer für Tabellen-Layout
    print_section() { printf "\n${C_MAIN}${C_BOLD}%s${C_RESET}\n" "$1"; }
    print_row() { printf "  ${C_ACCENT}%-10s${C_RESET}  %-20s  ${C_MUTED}%s${C_RESET}\n" "$1" "$2" "$3"; }

    print_section "⚡ WORKFLOW"
    print_row "gps" "Repo Manager"      "Projekte wechseln"
    print_row "gsw" "Branch Manager"    "Branches verwalten"
    print_row "gcw" "Commit Wizard"     "Smart Commit & Push"

    print_section "🛠  GIT BASICS"
    print_row "gs" "Status"             "Short Status"
    print_row "gl" "Pull"               "Rebase vom Remote"

    # Lade Favoriten aus der DNA/Config (falls vorhanden)
    local FAVORITES="$HOME/.config/git-suite/favorites"
    if [ -s "$FAVORITES" ]; then
        print_section "🌟 FAVORITES"
        while IFS='|' read -r c d _; do
            [[ -z "$c" || "$c" =~ ^# ]] && continue
            print_row "$c" "$d" "Custom Command"
        done < "$FAVORITES"
    fi

    printf "\n${C_MUTED}Tipp: Nutze 'gps -a' um den aktuellen Ordner zu registrieren.${C_RESET}\n"
}
