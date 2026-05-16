#!/bin/bash
bashdir="/home/bashers"
log="/var/log/tax_deletions.log"
limit=5120

mkdir -p "$(dirname "$log")"
touch "$log"
chown root:guards "$log"
chmod 640 "$log"

for dir in "$bashdir"/*/
do
    user=$(basename "$dir")
    usage=$(du -sk "$dir" 2>/dev/null | cut -f1)
    if [ $usage -gt $limit ]
    then
        mapfile -t files < <(find "$dir" -type f -printf '%T@ %s %p\n' 2>/dev/null | sort -n | head -3)
        for entry in "${files[@]}"
        do
            read -r _ size path <<< "$entry"
            fname=$(basename "$path")
            siz=$((size / 1024))
            echo "$(date '+%d-%m-%Y %H:%M:%S') | $user | $siz | $fname" >> "$log"
            rm -f "$path"
        done
    fi
done
