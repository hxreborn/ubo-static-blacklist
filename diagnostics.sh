#!/bin/bash
# Fetch all external filter lists from uBO backup and report rule counts + health

BACKUP="ubo-settings-backup.json"

if [ ! -f "$BACKUP" ]; then
    echo "Error: $BACKUP not found"
    exit 1
fi

# Extract imported list URLs from JSON
URLS=$(python3 -c "
import json, sys
with open('$BACKUP') as f:
    data = json.load(f)
for url in data['userSettings']['importedLists']:
    print(url)
")

echo "=== uBlock Origin Filter List Diagnostics ==="
echo "Source: $BACKUP"
echo "Date:   $(date '+%Y-%m-%d %H:%M')"
echo ""

total_all=0
total_procedural=0
total_generic=0
errors=()

while IFS= read -r url; do
    [ -z "$url" ] && continue

    # Derive short name from URL
    name=$(echo "$url" | sed -E '
        s|.*gist\.githubusercontent\.com/([^/]+)/.*|\1 (gist)|
        s|.*githubusercontent\.com/([^/]+)/([^/]+)/.*|\1/\2|
        s|.*github\.com/([^/]+)/([^/]+).*|\1/\2|
        s|.*gitflic\.ru/project/([^/]+)/([^/]+).*|\1/\2|
    ')

    # Fetch with status code check
    http_code=$(curl -sL -o /tmp/ubo-diag-tmp -w "%{http_code}" --max-time 15 "$url" 2>/dev/null)
    content=$(cat /tmp/ubo-diag-tmp 2>/dev/null)

    # Health checks
    if [ "$http_code" != "200" ]; then
        printf "%-45s  ❌ HTTP %s\n" "$name" "$http_code"
        errors+=("$name → HTTP $http_code")
        continue
    fi

    if [ -z "$content" ] || [ "$(echo "$content" | wc -c)" -lt 10 ]; then
        printf "%-45s  ⚠️  EMPTY RESPONSE\n" "$name"
        errors+=("$name → empty response")
        continue
    fi

    # Count non-empty, non-comment lines
    rules=$(echo "$content" | grep -cvE '^\s*$|^\s*!|^\s*#\s|^\[' || true)
    procedural=$(echo "$content" | grep -cP ':(has|has-text|matches-path|upward|matches-attr|matches-css|remove|style)\(' 2>/dev/null || true)
    generic=$(echo "$content" | grep -cP '^(\*##|##|\|\|)' 2>/dev/null || true)
    network=$(echo "$content" | grep -cP '^\|\|' 2>/dev/null || true)
    cosmetic=$(echo "$content" | grep -cP '##' 2>/dev/null || true)

    rules=${rules:-0}; procedural=${procedural:-0}; generic=${generic:-0}
    network=${network:-0}; cosmetic=${cosmetic:-0}

    total_all=$((total_all + rules))
    total_procedural=$((total_procedural + procedural))
    total_generic=$((total_generic + generic))

    if [ "$rules" -eq 0 ]; then
        printf "%-45s  ⚠️  0 RULES (fetched but no filters found)\n" "$name"
        errors+=("$name → 0 rules")
        continue
    fi

    printf "%-45s %5d rules  " "$name" "$rules"
    [ "$network" -gt 0 ] && printf "net:%-5d " "$network"
    [ "$cosmetic" -gt 0 ] && printf "css:%-5d " "$cosmetic"
    [ "$procedural" -gt 0 ] && printf "proc:%-4d " "$procedural"
    [ "$generic" -gt 0 ] && printf "gen:%-4d " "$generic"
    echo ""

done <<< "$URLS"

rm -f /tmp/ubo-diag-tmp

echo ""
echo "=== Summary ==="
echo "Total rules across all lists: $total_all"
echo "Total procedural filters:     $total_procedural"
echo "Total generic filters:        $total_generic"
echo "Lists with issues:            ${#errors[@]}"

if [ ${#errors[@]} -gt 0 ]; then
    echo ""
    echo "=== Issues ==="
    for err in "${errors[@]}"; do
        echo "  - $err"
    done
fi
