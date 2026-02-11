#!/bin/bash
# -----------------------------------------------------------------------------
# LAYER 2: FILESYSTEM ADAPTER
# Handhabt Datei-Operationen und JSON-Datenbankzugriffe.
# Kapselt die Python-Abhängigkeit für JSON-Parsing.
# -----------------------------------------------------------------------------

# @Intent: Stellt sicher, dass ein Verzeichnis existiert
# @Input: $1 (Path)
fs_ensure_dir() {
    mkdir -p "$1"
}

# @Intent: Prüft, ob eine Datei existiert und nicht leer ist
# @Input: $1 (Path)
fs_file_exists() {
    [ -s "$1" ]
}

# --- JSON DATABASE LOGIC (Repo Manager) ---
# Wir nutzen Python für robustes JSON-Handling, da Bash das nicht gut kann.
# Dies ist eine direkte Portierung der Logik aus dem alten 'gps'.

# @Intent: Listet alle Repos aus der JSON-DB
# @Input: $1 (JSON File Path), $2 (Optional Search Query)
# @Output: Format "Name|Path|Shortcut" pro Zeile
fs_db_list_repos() {
    local db="$1"
    local query="${2:-}"
    
    # Python-Skript (Inline)
    python3 -c "
import sys, json
try:
    with open(sys.argv[1]) as f: d = json.load(f)
except: d = []
query = sys.argv[2].lower()
for r in d:
    n = r.get('name', ''); p = r.get('path', ''); s = r.get('shortcut', '')
    if not query or query in n.lower() or query in s.lower():
        print(f'{n}|{p}|{s}')
" "$db" "$query"
}

# @Intent: Fügt ein Repo hinzu oder aktualisiert es (Upsert based on path)
# @Input: $1 (DB Path), $2 (Repo Path), $3 (Name), $4 (Shortcut)
fs_db_add_repo() {
    local db="$1"
    local path="$2"
    local name="$3"
    local short="$4"

    python3 -c "
import sys, json, os
db_file = sys.argv[1]
entry = {'name': sys.argv[3], 'path': sys.argv[2], 'shortcut': sys.argv[4]}
try:
    with open(db_file) as f: d = json.load(f)
except: d = []
# Remove existing with same path (Upsert behavior)
d = [i for i in d if i['path'] != entry['path']]
d.append(entry)
with open(db_file, 'w') as f: json.dump(d, f, indent=2)
" "$db" "$path" "$name" "$short"
}

# @Intent: Löscht ein Repo aus der DB
# @Input: $1 (DB Path), $2 (Repo Path to remove)
fs_db_delete_repo() {
    python3 -c "
import sys, json
db_file = sys.argv[1]
target = sys.argv[2]
try:
    with open(db_file) as f: d = json.load(f)
    d = [i for i in d if i['path'] != target]
    with open(db_file, 'w') as f: json.dump(d, f, indent=2)
except: pass
" "$1" "$2"
}
