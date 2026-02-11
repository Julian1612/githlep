#!/bin/bash
# -----------------------------------------------------------------------------
# LAYER 2: GIT ADAPTER
# Isoliert Git-Kommandos. Keine Business-Logik, nur Ausführung.
# -----------------------------------------------------------------------------

# @Intent: Prüft, ob wir in einem Git-Repo sind
# @Output: 0 (Ja), 1 (Nein)
git_check_is_repo() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# @Intent: Gibt den aktuellen Branch-Namen zurück
# @Output: String (z.B. "main")
git_get_current_branch() {
    git branch --show-current
}

# @Intent: Listet alle lokalen Branches auf
# @Output: Liste von Strings
git_get_branches() {
    git branch --format='%(refname:short)'
}

# @Intent: Prüft, ob ein Branch existiert
# @Input: $1 (Branch Name)
git_branch_exists() {
    git show-ref --verify --quiet "refs/heads/$1"
}

# @Intent: Wechselt den Branch
# @Input: $1 (Target Branch)
git_switch_branch() {
    local target="$1"
    git switch "$target" 2>&1
}

# @Intent: Erstellt einen neuen Branch und wechselt dorthin
# @Input: $1 (New Name)
git_create_branch() {
    local name="$1"
    git switch -c "$name" 2>&1
}

# @Intent: Löscht einen Branch (Force delete)
# @Input: $1 (Target Branch)
git_delete_branch() {
    local target="$1"
    git branch -D "$target" 2>&1
}

# @Intent: Benennt den aktuellen Branch um
# @Input: $1 (Old Name), $2 (New Name)
git_rename_branch() {
    local old="$1" # Wird aktuell implizit genutzt, aber gut für API
    local new="$2"
    git branch -m "$new" 2>&1
}

# @Intent: Führt einen Smart Pull (Rebase) durch
# @Output: stdout/stderr vom git befehl
git_pull_rebase() {
    git pull --rebase 2>&1
}

# @Intent: Holt den Status für die Prompt-Anzeige (Staged/Modified count)
# @Note: Einfache Implementierung für Speed
git_get_short_status() {
    git status -s
}
